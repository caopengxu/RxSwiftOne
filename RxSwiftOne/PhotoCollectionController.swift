//
//  PhotoCollectionController.swift
//  RxSwiftOne
//
//  Created by caopengxu on 2018/3/13.
//  Copyright © 2018年 caopengxu. All rights reserved.
//

import UIKit
import Photos
import RxSwift

class PhotoCollectionController: UICollectionViewController {
    
    fileprivate let selectedPhotosSubject = PublishSubject<UIImage>()
    var selectedPhotos: Observable<UIImage>
    {
        return selectedPhotosSubject.asObserver()
    }
    let bag = DisposeBag()

    fileprivate lazy var photos = PhotoCollectionController.loadPhotos()
    fileprivate lazy var imageManager = PHCachingImageManager()
    fileprivate lazy var thumbnailsize: CGSize = {
        let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        return CGSize(width: cellSize.width * UIScreen.main.scale,
                      height: cellSize.height * UIScreen.main.scale)
    }()
    
    // 界面显示前后
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        selectedPhotosSubject.onCompleted()
    }
    
    
    // viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置collectionView的样式
        setCellSpace()
    }
}


// MARK: === 访问相册获取图片
extension PhotoCollectionController
{
    static func loadPhotos() -> PHFetchResult<PHAsset>
    {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)];
        
        return PHAsset.fetchAssets(with: options)
    }
}


// MARK: === collectionView相关
extension PhotoCollectionController
{
    func setCellSpace()
    {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        let width = UIScreen.main.bounds.width
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        layout.itemSize = CGSize(width: (width - 40) / 4, height: (width - 40) / 4)
        collectionView!.collectionViewLayout = layout
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let asset = photos.object(at: indexPath.item)
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "PhotoMemo", for: indexPath
        ) as! PhotoCell
        
        cell.representedAssetIdentifier = asset.localIdentifier
        
        imageManager.requestImage(for: asset, targetSize: thumbnailsize, contentMode: .aspectFill, options: nil, resultHandler: {(image, _) in
            guard let image = image else {return}
            
            if cell.representedAssetIdentifier == asset.localIdentifier
            {
                cell.imageView.image = image
            }
        })
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let asset = photos.object(at: indexPath.item)
        
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell
        {
            cell.selected()
        }
        
        imageManager.requestImage(for: asset, targetSize: view.frame.size, contentMode: .aspectFill, options: nil, resultHandler: {[weak self] (image, info) in
            guard let image = image,
                let info = info else {return}
            
            if let isThumbnail = info[PHImageResultIsDegradedKey] as? Bool,
                !isThumbnail
            {
                self?.selectedPhotosSubject.onNext(image)
            }
        })
    }
}


