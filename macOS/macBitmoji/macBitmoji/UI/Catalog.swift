//
//  macBitmoji Edition
//
//  Catalog.swift
//  macBitmoji
//
//  Created by Mario Esposito on 4/7/20.
//

import Cocoa
import Quartz

class Catalog: NSViewController, QLPreviewPanelDataSource {

    // MARK: - IBOutlet Properties
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var tagsLabel: NSTextField!
    
    
    // MARK: - Properties
    var statusBarItem: NSStatusItem!
    var photos = [[PhotoInfo]]()
    
    let thumbnailSize = NSSize(width: 130.0, height: 130.0)
    var showSectionHeaders = false
    var previewURL: URL?
    let photoItemIdentifier: NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "photoItemIdentifier")
    
    
    // MARK: - VC Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1: hide things that aren't needed
        configureUI()
        
        // 2: setup image flow
        configureCollectionView()
        
        // 3: if cache doesn't exist create and load images otherwise just load images
        //loadCachedEmojis()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: SYSTEM MENU
    func setupMenuAndIcon() -> Void {
        let statusBar = NSStatusBar.system
        // Each item in that menu bar is an instance of NSStatusItem. We can make our own by using a Factory Method provided by the NSStatusBar instance.
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "🧤"
        
        // We’ll need an instance of NSMenu that will show the user options when they click on the menu bar extra icon.
        let statusBarMenu = NSMenu(title: "Cap Status Bar Menu")
        // associate our new menu with the status item we created earlier
        statusBarItem.menu = statusBarMenu
        // build the menu
        statusBarMenu.addItem(
                withTitle: "Avatars",
                action: #selector(self.getAvatars),
                keyEquivalent: "")

            statusBarMenu.addItem(
                withTitle: "About",
                action: #selector(self.about),
                keyEquivalent: "")
    }
    
    // MARK: ACTIONS
    
    @objc func getAvatars() {
        print("Ordering a burrito!")
    }

    @objc func about() {
        print("Canceling your order :(")
    }
    
    
    
    // MARK: - Implemented Methods
    
    func configureUI() {
        self.progressBar.isHidden = true
        tagsLabel.stringValue = ""
        setupMenuAndIcon()
    }
    
    
    func prepareToCreateThumbnails(for totalPhotos: Int) {
        progressBar.isHidden = false
        progressBar.minValue = 0.0
        progressBar.maxValue = Double(totalPhotos)
        progressBar.doubleValue = 0.0
    }
    
    
    func performPostThumbnailCreationActions() {
        progressBar.isHidden = true
    }
    
    
    func updateProgress(withValue value: Int) {
        progressBar.doubleValue = Double(value)
    }
    
    
    func getProcessedPhotos() {
        if photos.count > 0 {
            self.photos[self.photos.count - 1] = PhotoHelper.shared.photosToProcess
        }
    }
    
    
    func configureAndShowQuickLook() {
        guard let ql = QLPreviewPanel.shared() else { return }
        ql.dataSource = self
        ql.makeKeyAndOrderFront(self.view.window)
    }
    
    
    
    // MARK: - QLPreviewPanelDataSource
       
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return 1
    }

    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        guard let previewURL = previewURL else { return nil }
        return previewURL as QLPreviewItem
    }
    
    
    
    // MARK: - IBOutlet Properties
    
    @IBAction func importPhotos(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        panel.message = "Select a folder to import photos from..."
        let response = panel.runModal()
        
        if response == NSApplication.ModalResponse.OK {
            if let selectedURL = panel.directoryURL {
                var newPhotos = [PhotoInfo]()
                PhotoHelper.shared.importPhotoURLs(from: selectedURL, to: &newPhotos)
                photos.append(newPhotos)
                
                createThumbnails()
            }
        }
    }
    
    
    
    // MARK: - Put Methods To Implement Here
    
    func createThumbnails() {
        guard let recentPhotos = photos.last else { return }
        prepareToCreateThumbnails(for: recentPhotos.count)
        PhotoHelper.shared.createThumbnails(for: recentPhotos, desiredSize: thumbnailSize, progress: { (currentPhoto) in
            
            DispatchQueue.main.async {
                self.updateProgress(withValue: currentPhoto)

                if currentPhoto.isMultiple(of: 20) {
                    self.getProcessedPhotos()

                    self.collectionView.reloadData()
                    self.collectionView.enclosingScrollView?.contentView.scroll(to:
                        NSPoint(x: 0.0, y: self.collectionView.collectionViewLayout?.collectionViewContentSize.height ?? 0.0))
                }
            }
            
           }) { () in
                DispatchQueue.main.async {
                    self.getProcessedPhotos()
                    self.performPostThumbnailCreationActions()
                    self.collectionView.reloadData()
                    self.collectionView.enclosingScrollView?.contentView.scroll(to: NSPoint(x: 0.0, y: 0.0))
                }
           }
    }
    
    
    func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isSelectable = true
        collectionView.allowsEmptySelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.enclosingScrollView?.borderType = .noBorder
        collectionView.register(NSNib(nibNamed: "PhotoItem", bundle: nil), forItemWithIdentifier: photoItemIdentifier)
        
        configureFlowLayout()
    }
    

    func configureFlowLayout() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 30.0
        flowLayout.minimumLineSpacing = 30.0
        flowLayout.sectionInset = NSEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
        collectionView.collectionViewLayout = flowLayout
    }
    
    func loadCachedEmojis() {
    
        // check that the cache folder exists
        
        // load photos
        let selectedURL = URL(fileURLWithPath: "/Users/mario/Pictures")
        var newPhotos = [PhotoInfo]()
        PhotoHelper.shared.importPhotoURLs(from: selectedURL, to: &newPhotos)
        photos.append(newPhotos)
        
        createThumbnails()

    }
}



// MARK: - NSCollectionViewDataSource
extension Catalog: NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return photos.count
    }
    
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos[section].count
    }
    
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        guard let item = collectionView.makeItem(withIdentifier: photoItemIdentifier, for: indexPath) as? PhotoItem else { return NSCollectionViewItem() }
        
        item.imageView?.image = photos[indexPath.section][indexPath.item].thumbnail
        
        item.doubleClickActionHandler = { [weak self] in
            self?.previewURL = self?.photos[indexPath.section][indexPath.item].url
            self?.configureAndShowQuickLook()
        }
        
        return item
    }
}



// MARK: - NSCollectionViewDelegateFlowLayout
extension Catalog: NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {

        guard let indexPath = indexPaths.first else { return }
        
        guard let url = photos[indexPath.section][indexPath.item].url else { tagsLabel.stringValue = ""; return }
        tagsLabel.stringValue = url.lastPathComponent
    }
    
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: 150.0, height: 150.0)
    }
    
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        
        return showSectionHeaders ? NSSize(width: 0.0, height: 60.0) : .zero
    }
}
