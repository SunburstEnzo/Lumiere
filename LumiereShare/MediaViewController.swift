//
//  MediaViewController.swift
//  LumiereShare
//
//  Created by Aled Samuel on 26/01/2021.
//

import UIKit
import SDWebImage
import AVKit
import Photos

import ComposableRequest
import ComposableRequestCrypto
import Swiftagram


struct InstagramMedia {
	
	enum MediaType {
		
		case picture
		case video
		case album
	}
	
	struct ImageVersions {
		
		let images: [Image]
	}
	
	struct Image {
		
		let url: URL
		let width: CGFloat
		let height: CGFloat
	}
	
	let caption: String?
	let mediaType: MediaType
	let imageVersions: [ImageVersions]
	let videoURLs: [URL]
}


final class MediaViewController: UIViewController {
	
	
	// MARK: Statics
	
	private static let cellIdentifier = "cellIdentifier"
	private static let videoCellIdentifier = "videoCellIdentifier"
	
	
	// MARK: Properties
	
	private let activityIndicator: UIActivityIndicatorView = {
		
		let activityIndicator = UIActivityIndicatorView(style: .large)
		activityIndicator.color = .label
		activityIndicator.sizeToFit()
		return activityIndicator
	}()
	
	private let galleryCollectionView: UICollectionView = {
		
		let flowLayout = UICollectionViewFlowLayout()
		flowLayout.minimumInteritemSpacing = 0
		flowLayout.minimumLineSpacing = 0
		flowLayout.scrollDirection = .horizontal
		
		let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
		collectionView.backgroundColor = .secondarySystemBackground
		collectionView.isPagingEnabled = true
		collectionView.alwaysBounceHorizontal = true
		
		collectionView.register(GalleryImageCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
		collectionView.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: videoCellIdentifier)
		
		return collectionView
	}()
	
	private var instagramMedia: InstagramMedia? {
		
		didSet {
			
			updateInstagramMedia()
		}
	}
	
	private let secret: Secret
	
	private var mediaID: String
	
	
	// MARK: Init
	
	init(secret: Secret, mediaID: String) {
		
		self.secret = secret
		self.mediaID = mediaID
		
		super.init(nibName: nil, bundle: nil)
		
		requestInfo(for: mediaID)
	}
	
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) is not supported")
	}
	
	
	// MARK: View lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = "Lumiere"
		
		view.backgroundColor = .systemBackground
		
		navigationController?.navigationBar.prefersLargeTitles = true
		
		let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(handleDismissButton(_:)))
		navigationItem.rightBarButtonItem = closeButton
		
		navigationItem.hidesBackButton = true
		
		galleryCollectionView.dataSource = self
		galleryCollectionView.delegate = self
		view.addSubview(galleryCollectionView)
		
		activityIndicator.startAnimating()
		view.addSubview(activityIndicator)
	}
	
	
	// MARK: Layout
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		activityIndicator.center = CGPoint(x: view.bounds.width.half, y: view.bounds.height.half)
		
		galleryCollectionView.frame = CGRect(x: 0, y: view.safeAreaInsets.top, width: view.bounds.width, height: view.bounds.height - view.safeAreaInsets.bottom - view.safeAreaInsets.top)
		
		(galleryCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: galleryCollectionView.bounds.width, height: galleryCollectionView.bounds.height)
		(galleryCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.headerReferenceSize = .zero
		(galleryCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.footerReferenceSize = .zero
	}
	
	
	// MARK: Handlers
	
	@objc private func handleDismissButton(_ sender: UIBarButtonItem) {
		
		dismissCurrent()
	}
	
	
	private func dismissCurrent() {
		
		if let extensionContext = extensionContext {
			
			extensionContext.completeRequest(returningItems: nil, completionHandler: nil)
		}
		else {
			
			dismiss(animated: true, completion: nil)
		}
	}
	
	
	private func updateInstagramMedia() {
		
		title = instagramMedia?.caption ?? "Lumiere"
		
		galleryCollectionView.reloadData()
		
		activityIndicator.stopAnimating()
		activityIndicator.isHidden = true
	}
	
	
	private func requestInfo(for mediaID: String) {
		
		Endpoint.Media.summary(for: mediaID)
			.unlocking(with: secret)
			.task { [weak self] (result) in
				
				switch result {
				case .success(let media):
					
					if let mediaError = media.error {
						
						self?.presentMediaFailure(with: mediaError)
						
						self?.updateInstagramMedia()
					}
					
					let caption = media.media?.first?.caption?.text ?? "Lumiere"
					
					if let content = media.media?.first?.content {
						
						var imageVersions = [InstagramMedia.ImageVersions]()
						var videoURLs = [URL]()
						
						let mediaType: InstagramMedia.MediaType
						
						switch content {
						case .picture(let picture):
							
							mediaType = .picture
							
							let images = self?.imagesFromImageVersions(imageVersions: picture.images) ?? []
							imageVersions.append(InstagramMedia.ImageVersions(images: images))
							
						case .video(let video):
							
							mediaType = .video
							
							if let videoURL = video.clips?.first?.url {
								
								videoURLs.append(videoURL)
							}
							
							let images = self?.imagesFromImageVersions(imageVersions: video.images) ?? []
							imageVersions.append(InstagramMedia.ImageVersions(images: images))
							
						case .album(let album):
							
							mediaType = .album
							
							for item in album {
								
								switch item {
								case .picture(let picture):
									
									let images = self?.imagesFromImageVersions(imageVersions: picture.images) ?? []
									imageVersions.append(InstagramMedia.ImageVersions(images: images))
									
								case .video(let video):
									
									if let videoURL = video.clips?.first?.url {
										
										videoURLs.append(videoURL)
									}
									
									let images = self?.imagesFromImageVersions(imageVersions: video.images) ?? []
									imageVersions.append(InstagramMedia.ImageVersions(images: images))
									
								default:
									break
								}
							}
							
						default:
							
							mediaType = .picture
						}
						
						self?.instagramMedia = InstagramMedia(caption: caption, mediaType: mediaType, imageVersions: imageVersions, videoURLs: videoURLs)
					}
					
				case .failure(let error):
					
					print(error.localizedDescription)
				}
			}
			.resume()
	}
	
	
	private func imagesFromImageVersions(imageVersions: [Media.Version]?) -> [InstagramMedia.Image] {
		
		var images = [InstagramMedia.Image]()
		
		if let pictureImages = imageVersions {
			
			for pictureImage in pictureImages {
				
				if let url = pictureImage.url, let size = pictureImage.size {
					
					let image = InstagramMedia.Image(url: url, width: size.width, height: size.height)
					images.append(image)
				}
			}
		}
		
		return images.sorted(by: { $0.height > $1.height })
	}
}


// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension MediaViewController: UICollectionViewDataSource, UICollectionViewDelegate {
	
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		
		/// 0: Images
		/// 1: Videos
		
		return 2
	}
	
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		
		if section == 0 {
			
			return instagramMedia?.imageVersions.count ?? 0
		}
		
		return instagramMedia?.videoURLs.count ?? 0
	}
	
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		if indexPath.section == 0 {
			
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellIdentifier, for: indexPath) as! GalleryImageCollectionViewCell
			
			cell.imageURL = instagramMedia?.imageVersions[indexPath.item].images.first?.url
			
			return cell
		}
		else {
			
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.videoCellIdentifier, for: indexPath) as! VideoCollectionViewCell
			
			cell.videoURL = instagramMedia?.videoURLs[indexPath.item]
			
			return cell
		}
	}
	
	
	func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		
		if let cell = galleryCollectionView.cellForItem(at: indexPath) as? VideoCollectionViewCell {
			
			cell.playVideo()
		}
	}
	
	
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		
		for cell in collectionView.visibleCells {
			
			guard collectionView.indexPath(for: cell) != indexPath else { return }
			
			if let videoCell = cell as? VideoCollectionViewCell {
				
				videoCell.pauseVideo()
			}
		}
	}
	
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		
		if indexPath.section == 0 {
			
			presentImageSaveOptions(at: indexPath)
		}
		else if let cell = galleryCollectionView.cellForItem(at: indexPath) as? VideoCollectionViewCell {
			
			cell.presentFullscreen()
		}
	}
	
	
	private func presentImageSaveOptions(at indexPath: IndexPath) {
		
		if indexPath.section == 0 {
			
			if let images = instagramMedia?.imageVersions[indexPath.item].images {
				
				let title = "Image \(indexPath.item + 1) of \(instagramMedia?.imageVersions.count ?? 0)"
				
				let actionSheet = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
				actionSheet.view.tintColor = UIColor(patternImage: #imageLiteral(resourceName: "GradientImage"))
				
				actionSheet.modalPresentationStyle = .popover
				actionSheet.popoverPresentationController?.sourceView = galleryCollectionView
				actionSheet.popoverPresentationController?.sourceRect = CGRect(x: galleryCollectionView.bounds.width.half, y: galleryCollectionView.bounds.height.half, width: 0, height: 0) //galleryCollectionView.bounds
				
				for image in images {
					
					let title = NSLocalizedString("Save Image", comment: "") + " (\(image.width) ✕ \(image.height))"
					
					let saveAction = UIAlertAction(title: title, style: .default) { [weak self] _ in
						
						SDWebImageManager.shared.loadImage(with: image.url, options: [], progress: nil) { [weak self] (image, _, error, _, finished, _) in
							
							if finished, let image = image {
								
								self?.saveImage(image)
							}
						}
					}
					
					actionSheet.addAction(saveAction)
				}
				
				let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
				actionSheet.addAction(cancelAction)
				
				present(actionSheet, animated: true, completion: nil)
			}
		}
	}
	
	
	private func saveImage(_ image: UIImage) {
		
		PHPhotoLibrary.shared().performChanges {
			
			PHAssetChangeRequest.creationRequestForAsset(from: image)
			
		} completionHandler: { [weak self] (success, error) in
			
			let alertString: String
			let messageString: String
			
			if success {
				
				alertString = NSLocalizedString("Success!", comment: "")
				messageString = NSLocalizedString("Image saved successfully", comment: "")
				
			} else {
				
				alertString = NSLocalizedString("Save Failed", comment: "")
				messageString = error?.localizedDescription ?? NSLocalizedString("Failed to save image", comment: "")
			}
			
			let alert = UIAlertController(title: alertString, message: messageString, preferredStyle: .alert)
			
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			
			DispatchQueue.main.async { [weak self] in
				
				self?.present(alert, animated: true, completion: nil)
			}
		}
	}
		
	
	private func saveVideo(at indexPath: IndexPath) {
		
		if let cell = galleryCollectionView.cellForItem(at: indexPath) as? VideoCollectionViewCell {
			
			guard let videoURL = cell.videoURL else {
				
				presentSaveFailureAlert(with: NSLocalizedString("Missing video URL", comment: ""))
				return
			}
			
			let task = URLSession.shared.downloadTask(with: videoURL) { [weak self] (localURL, response, error) in
				
				guard let localURL = localURL else {
					
					self?.presentSaveFailureAlert(with: NSLocalizedString("Invalid URL", comment: ""))
					return
				}
				
				let lastPathComponent = videoURL.lastPathComponent
				
				guard let urlData = NSData(contentsOf: localURL) else {
					
					self?.presentSaveFailureAlert(with: NSLocalizedString("Failed to create data with contents of URL", comment: ""))
					return
				}
				
				guard let galleryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
					
					self?.presentSaveFailureAlert(with: NSLocalizedString("Failed to create directory path", comment: ""))
					return
				}
				
				let filePath = "\(galleryPath)/\(lastPathComponent)"
				
				urlData.write(toFile: filePath, atomically: true)
				
				PHPhotoLibrary.shared().performChanges {
					
					PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
					
				} completionHandler: { [weak self] (success, error) in
					
					let alertString: String
					let messageString: String
					
					if success {
						
						alertString = NSLocalizedString("Success!", comment: "")
						messageString = NSLocalizedString("Video saved successfully", comment: "")
						
					} else {
						
						alertString = NSLocalizedString("Save Failed", comment: "")
						messageString = error?.localizedDescription ?? NSLocalizedString("Failed to save video", comment: "")
					}
					
					let alert = UIAlertController(title: alertString, message: messageString, preferredStyle: .alert)
					
					alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
					
					DispatchQueue.main.async { [weak self] in
						
						self?.present(alert, animated: true, completion: nil)
					}
				}
			}
			
			task.resume()
		}
	}
	
	
	private func presentSaveFailureAlert(with errorMessage: String) {
		
		let alertString = NSLocalizedString("Save Failed", comment: "")
		
		let alert = UIAlertController(title: alertString, message: errorMessage, preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		
		DispatchQueue.main.async { [weak self] in
			
			self?.present(alert, animated: true, completion: nil)
		}
	}
	
	
	private func presentMediaFailure(with mediaError: ResponseError) {
		
		let alertString = NSLocalizedString("Media Error", comment: "")
		
		let errorMessage: String?
		
		switch mediaError {
		case .generic(let message): errorMessage = message
		case .unforseen(let message):
			
			if let message = message { errorMessage = message }
			else { fallthrough }
			
		case .unknown: errorMessage = NSLocalizedString("Unknown error", comment: "")
		}
		
		let alert = UIAlertController(title: alertString, message: errorMessage, preferredStyle: .alert)
		alert.view.tintColor = UIColor(patternImage: #imageLiteral(resourceName: "GradientImage"))
		
		let closeAction = UIAlertAction(title: NSLocalizedString("Close", comment: ""), style: .default) { [weak self] _ in
			
			self?.dismissCurrent()
		}
		
		alert.addAction(closeAction)
		
		DispatchQueue.main.async { [weak self] in
			
			self?.present(alert, animated: true, completion: nil)
		}
	}
	
	
	@available(iOS 13.0, *)
	func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		
		let menuActions: [UIMenuElement]?
		
		let saveAction: UIAction
		
		let title: String
		
		if indexPath.section == 0 {
			
			title = "Image \(indexPath.item + 1) of \(instagramMedia?.imageVersions.count ?? 0)"
			
			saveAction = UIAction(title: NSLocalizedString("Save Image", comment: ""), image: UIImage(systemName: "photo")) { [weak self] (action) in
				
				self?.presentImageSaveOptions(at: indexPath)
			}
		}
		else {
			
			title = "Video \(indexPath.item + 1) of \(instagramMedia?.videoURLs.count ?? 0)"
			
			saveAction = UIAction(title: NSLocalizedString("Save Video", comment: ""), image: UIImage(systemName: "video")) { [weak self] (action) in
				
				self?.saveVideo(at: indexPath)
			}
		}
		
		menuActions = [saveAction]
		
		return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil) { (suggestedActions) -> UIMenu? in
			
			if let menuActions = menuActions {
				
				return UIMenu(title: title, children: menuActions)
			}
			
			return nil
		}
	}
	
	
	@available(iOS 13.0, *)
	func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
		
		return
	}
	
	
	@available(iOS 13.0, *)
	private func collectionView(_ collectionView: UICollectionView, cellPreviewForContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		
		return nil
	}
	
	
	@available(iOS 13.0, *)
	func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		
		self.collectionView(collectionView, cellPreviewForContextMenuWithConfiguration: configuration)
	}
	
	
	@available(iOS 13.0, *)
	func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		
		self.collectionView(collectionView, cellPreviewForContextMenuWithConfiguration: configuration)
	}
}



// MARK: - GalleryImageCollectionViewCell

final private class GalleryImageCollectionViewCell: UICollectionViewCell {
	
	
	private let imageView: UIImageView = {
		
		let imageView = UIImageView()
		imageView.contentMode = .scaleAspectFit
		imageView.clipsToBounds = true
		imageView.sd_imageIndicator = SDWebImageActivityIndicator.large
		return imageView
	}()
	
	var imageURL: URL? {
		
		didSet {
			
			imageView.sd_setImage(with: imageURL) { [weak self] (image, error, _, _) in
				
				self?.image = image
			}
		}
	}
	
	private(set) var image: UIImage?
	
	override var isHighlighted: Bool {
		
		didSet {
			
			imageView.alpha = isHighlighted ? 0.5 : 1
		}
	}
	
	
	// MARK: Init
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		contentView.backgroundColor = .secondarySystemBackground
		contentView.clipsToBounds = true
		contentView.addSubview(imageView)
	}
	
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) is not supported")
	}
	
	
	// MARK: Layout
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		imageView.frame = contentView.bounds
	}
}



// MARK: - VideoCollectionViewCell

final private class VideoCollectionViewCell: UICollectionViewCell {
	
	
	private var playerViewController: AVPlayerViewController?
	
	private var player: AVPlayer?
	
	var videoURL: URL? {
		
		didSet {
			
			setupVideo()
		}
	}
	
	
	// MARK: Init
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		contentView.backgroundColor = .secondarySystemBackground
		contentView.clipsToBounds = true
	}
	
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) is not supported")
	}
	
	
	// MARK: Layout
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		playerViewController?.view.frame = contentView.bounds
	}
	
	
	// MARK: Video
	
	private func setupVideo() {
		
		playerViewController?.removeFromParent()
		playerViewController = nil
		
		guard let url = videoURL else { return }
		
		playerViewController = AVPlayerViewController()
		playerViewController?.player = AVPlayer(url: url)
		
		contentView.addSubview(playerViewController!.view)
		
		playerViewController?.player?.isMuted = true
		playerViewController?.player?.play()
	}
	
	
	func playVideo() {
		
		playerViewController?.player?.play()
	}
	
	
	func pauseVideo() {
		
		playerViewController?.player?.pause()
	}
	
	
	func presentFullscreen() {
		
		/// Note: Be wary of using the selector approach, may result in undefined behaviour
		
		guard let playerViewController = playerViewController else { return }
		
		let selectorName = "_transitionToFullScreenAnimated:interactive:completionHandler:"
		
		let selector = NSSelectorFromString(selectorName)
		
		if playerViewController.responds(to: selector) {
			
			playerViewController.perform(selector, with: true, with: nil)
		}
	}
}
