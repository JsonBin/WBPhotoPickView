//
//  WBPhotoPickView.swift
//  WBPhotoPickView
//
//  Created by Zwb on 16/4/12.
//  Copyright © 2016年 zwb. All rights reserved.
//

import UIKit
import AssetsLibrary
import Photos

// 从照片库获取照片
class WBPhotoPickView: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    internal var allowEditing:Bool?  // 标记照片是否可编辑,默认不可编辑
    internal var photoCount:NSInteger? // 需要选择照片的数量,默认数量为5
    internal var photoArray:((photo:NSArray)->Void)?
    
    private let tableView=UITableView()
    private let nameArray=NSMutableArray()
    private let imageArray=NSMutableArray()
    
    internal func selectPhoto(photos:(photo:NSArray)->Void) -> Void{
        photoArray=photos
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title="照片"
        self.view.backgroundColor=UIColor.whiteColor()
        // cancle
        let rightBar=UIBarButtonItem.init(barButtonSystemItem: .Cancel, target: self, action: #selector(self.cancle))
        self.navigationItem.rightBarButtonItem=rightBar
        
        let authorizationStatus=ALAssetsLibrary.authorizationStatus()
        if authorizationStatus != ALAuthorizationStatus.Authorized {
            let dic=NSBundle.mainBundle().infoDictionary
            let appname=dic!["CFBundleDisplayName"]
            let str="请在设备的\"设置-隐私-照片\"选项中，允许\(appname)访问你的手机相册"
            let label=UILabel()
            label.frame=self.view.bounds
            label.textAlignment = .Center
            label.font=UIFont.systemFontOfSize(20)
            label.textColor=UIColor ( red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0 )
            label.lineBreakMode = .ByTruncatingTail
            label.numberOfLines=0
            label.sizeToFit()
            label.text = str
            self.view.addSubview(label)
            return
        }
        
        // ios 大于8.0 用photokit框架
        weak var weakSelf=self
        if #available(iOS 8.0, *) {
            let alibrary:PHFetchResult=PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .AlbumRegular, options: nil)
            // 设置照片裁剪大小
//            let win=UIApplication.sharedApplication().keyWindow!
//            let manageSize=CGSizeMake(win.bounds.width, win.bounds.width)
            for i in 0..<alibrary.count {
                let collect:PHCollection = alibrary[i] as! PHCollection
                
                let manage=PHCachingImageManager()
                let assetCollection:PHAssetCollection=collect as! PHAssetCollection
                let asarray=PHAsset.fetchAssetsInAssetCollection(assetCollection, options: nil)
                if asarray.count>0{
                    let im_array=NSMutableArray()
                    let options=PHImageRequestOptions()
                    options.synchronous=true  // 设置为同步方式
                    for index in 0..<asarray.count {
                        manage.requestImageForAsset((asarray[index] as! PHAsset), targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.Default, options: options, resultHandler: { (image, dic) in
                                im_array.addObject(image!)
                        })
                    }
                    if im_array.count>0 {
                        nameArray.addObject(collect.localizedTitle!)
                        imageArray.addObject(im_array)
                        tableView.reloadData()
                    }
                }
            }
        }else{
            let alibrary=ALAssetsLibrary.init()
            alibrary.enumerateGroupsWithTypes(ALAssetsGroupAll, usingBlock: { (group, stop) in
                if group != nil{
                    let array=NSMutableArray()
                    group.enumerateAssetsUsingBlock({ (result, index, finish) in
                        if result != nil{
                            array.addObject(result.thumbnail().takeUnretainedValue())
                        }
                    })
                    if array.count>0{
                        weakSelf?.imageArray.addObject(array)
                        weakSelf?.nameArray.addObject(group.valueForProperty("ALAssetsGroupPropertyName"))
                        weakSelf?.tableView.reloadData()
                    }
                }
            }) { (error) in
                print("获取相册资源失败")
            }
        }
        
        tableView.frame=self.view.bounds
        tableView.dataSource=self
        tableView.delegate=self
        tableView.tableFooterView=UIView()
        self.view.addSubview(tableView)
    }
    
    // 取消
    internal func cancle()->Void{
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    //MARK: UITableViewDataSource
    internal func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    internal func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell")
        if  cell==nil {
            cell=UITableViewCell.init(style: .Subtitle, reuseIdentifier: "cell")
            if  #available(iOS 8.0, *) {
                cell?.imageView?.image=(imageArray[indexPath.row].lastObject) as? UIImage
            }else{
                cell?.imageView?.image=UIImage.init(CGImage: (imageArray[indexPath.row].lastObject as! CGImage))
            }
            cell?.textLabel?.text=nameArray[indexPath.row] as? String
            cell?.detailTextLabel?.textColor=UIColor ( red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0 )
            cell?.detailTextLabel?.text=(NSString.init(format:"%ld", imageArray[indexPath.row].count) as String).stringByAppendingString(" 张照片")
            cell?.accessoryType = .DisclosureIndicator
        }
        return cell!
    }
    
    //MARK: UITableViewDelegate
    internal func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    // 选择相册
    internal func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let select=WBPhotoSelectView()
        select.title=nameArray[indexPath.row] as? String
        select.array=imageArray[indexPath.row] as! NSArray
        select.allowEditing = allowEditing==nil ? false : allowEditing!
        select.photoCount = photoCount==nil ? 5 : photoCount!
        weak var weakSelf=self
        select.photo { (imagearray) in
            if ((weakSelf?.photoArray) != nil) {
                weakSelf?.photoArray!(photo: imagearray)
            }
        }
        self.navigationController?.pushViewController(select, animated: true)
    }
}

// 多选照片
class WBPhotoSelectView: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    internal var allowEditing=Bool()  // 标记照片是否可编辑
    internal var photoCount=NSInteger() // 需要选择照片的数量
    internal var array=NSArray() // 相册内的相片数据
    internal var photoArray:((imagearray:NSArray)->Void)?
    
    private var colloection:UICollectionView?
    private let selectArray=NSMutableArray()
    
    internal func photo(image:(imagearray:NSArray)->Void) -> Void{
        photoArray=image
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.view.backgroundColor=UIColor.whiteColor()
        // cancle
        let rightBar=UIBarButtonItem.init(barButtonSystemItem: .Done, target: self, action: #selector(self.done))
        self.navigationItem.rightBarButtonItem=rightBar
        
        let flowlayout=UICollectionViewFlowLayout()
        flowlayout.minimumLineSpacing=2
        flowlayout.minimumInteritemSpacing=2
        flowlayout.itemSize=CGSizeMake((self.view.bounds.width-8)/4, (self.view.bounds.width-8)/4)
        colloection=UICollectionView.init(frame: self.view.bounds, collectionViewLayout: flowlayout)
        colloection!.backgroundColor=UIColor.whiteColor()
        colloection!.allowsMultipleSelection=true
        colloection!.delegate=self
        colloection!.dataSource=self
        colloection!.registerClass(WBPhotoSelectViewCell.classForKeyedArchiver(), forCellWithReuseIdentifier: "imagecell")
        self.view.addSubview(colloection!)
    }
    // 完成选择
    internal func done()->Void{
        if (photoArray != nil) {
            var arraydone=NSMutableArray()
            if #available(iOS 8.0, *) {
                arraydone=selectArray
            }else{
                for index in 0..<selectArray.count {
                    arraydone.addObject(UIImage.init(CGImage: selectArray[index] as! CGImage))
                }
            }
            photoArray!(imagearray: arraydone)
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: UICollectionViewDataSource
    internal func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return array.count
    }
    
    internal func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell:WBPhotoSelectViewCell=(collectionView.dequeueReusableCellWithReuseIdentifier("imagecell", forIndexPath: indexPath)) as! WBPhotoSelectViewCell
        if #available(iOS 8.0, *) {
            cell.imageView.image=array[indexPath.row] as? UIImage
        }else{
            cell.imageView.image=UIImage.init(CGImage: array[indexPath.row] as! CGImage)
        }
        // 选择回调
        weak var weakSelf=self
        cell.initIndex { (flag) in
            if flag {
                if (weakSelf?.selectArray.count)!>(weakSelf?.photoCount)!-1{
                    print("select photo count is more \(weakSelf?.photoCount).")
                    cell.button.selected=false
                    cell.selectShaplayer.fillColor=UIColor.whiteColor().CGColor
                    cell.mask.removeFromSuperview()
                    // 提示
                    let label=UILabel()
                    let win=UIApplication.sharedApplication().keyWindow!
                    label.bounds=CGRectMake(0, 0, win.bounds.size.width/2+40, 20)
                    label.center=win.center
                    label.textAlignment = .Center
                    label.layer.cornerRadius=2
                    label.text="最多能选择 \(NSString.init(format: "%ld", (weakSelf?.photoCount)!) as String) 张照片!"
                    label.font=UIFont.systemFontOfSize(15)
                    label.textColor=UIColor.whiteColor()
                    label.backgroundColor=UIColor ( red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5 )
                    win.addSubview(label)
                    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
                    dispatch_after(time, dispatch_get_main_queue()) {
                        label.removeFromSuperview()
                    }
                }else{
                    weakSelf?.selectArray.addObject((weakSelf?.array[indexPath.row])!)
                }
            }else{
                if weakSelf?.selectArray.count>0{
                    weakSelf?.selectArray.removeObject((weakSelf?.array[indexPath.row])!)
                }
            }
        }
        
        return cell
    }
    // 偏移，上 10 左 1 下 0 右 1
    internal func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10, 1, 0, 1)
    }
    
    //MARK: UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if allowEditing {       // 查看照片 (还未开发)
            
        }
    }
}

// 自定义cell
class WBPhotoSelectViewCell: UICollectionViewCell {
    
    internal var imageView=UIImageView()
    // 回调index
    internal var index:((flag:Bool)->Void)?
    internal let button=UIButton()
    
    private let mask=UIView()
    private let selectLayer=CALayer()
    private let selectShaplayer=CAShapeLayer()
    
    internal func initIndex(count:(flag:Bool)->Void) -> Void{
        index=count
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.frame=self.bounds
        self.contentView.addSubview(imageView)
        
        selectLayer.position = CGPointMake(self.bounds.width-15, 15)
        selectLayer.cornerRadius=15
        selectLayer.bounds = CGRectMake(0, 0, 30, 30)
        selectLayer.backgroundColor = UIColor ( red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0 ).CGColor
        imageView.layer.addSublayer(selectLayer)
        
        let path  = UIBezierPath()
        path.moveToPoint(CGPointMake(10, 12))
        path.addLineToPoint(CGPointMake(15, 16))
        path.addLineToPoint(CGPointMake(22, 8))
        path.addLineToPoint(CGPointMake(24, 10))
        path.addLineToPoint(CGPointMake(15, 20))
        path.addLineToPoint(CGPointMake(8, 14))
        path.closePath()
        
        selectShaplayer.path = path.CGPath
        selectShaplayer.lineWidth = 0.8
        selectShaplayer.strokeColor=UIColor.clearColor().CGColor
        selectShaplayer.fillColor = UIColor.whiteColor().CGColor
        layer.position = self.center
        selectLayer.addSublayer(selectShaplayer)
        
        button.frame=CGRectMake(self.bounds.width-30, 0, 30, 30)
        button.backgroundColor=UIColor.clearColor()
        button.addTarget(self, action: #selector(self.selectImage(_:)), forControlEvents: .TouchUpInside)
        self.contentView.addSubview(button)
        
        mask.frame=self.bounds
        mask.backgroundColor=UIColor ( red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4 )
    }
    
    internal func selectImage(sender:UIButton)->Void{
        sender.selected = !sender.selected
        if sender.selected {
            selectShaplayer.fillColor=UIColor.greenColor().CGColor
            self.contentView.insertSubview(mask, aboveSubview: imageView)
            
            if (index != nil) {
                index!(flag: true)
            }
            
        }else{
            selectShaplayer.fillColor = UIColor.whiteColor().CGColor
            mask.removeFromSuperview()
            
            if (index != nil) {
                index!(flag: false)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /*
    private func creatLayer()->CALayer{
        let layer = CALayer()
        layer.position = CGPointMake(self.bounds.width-30, 15)
        layer.bounds = CGRectMake(0, 0, 30, 30)
        layer.backgroundColor = UIColor ( red: 0.502, green: 0.502, blue: 0.502, alpha: 1.0 ).CGColor
        return layer
    }
    
    private func createShapLayer()->CAShapeLayer{
        let layer = CAShapeLayer()
        let path  = UIBezierPath()
        path.moveToPoint(CGPointMake(10, 12))
        path.addLineToPoint(CGPointMake(15, 15))
        path.addLineToPoint(CGPointMake(20, 10))
        path.addLineToPoint(CGPointMake(22, 12))
        path.addLineToPoint(CGPointMake(15, 18))
        path.addLineToPoint(CGPointMake(8, 10))
        path.closePath()
        
        layer.path = path.CGPath
        layer.lineWidth = 0.8
        layer.fillColor = UIColor.whiteColor().CGColor
        let bound = CGPathCreateCopyByStrokingPath(layer.path, nil, layer.lineWidth, CGLineCap.Butt, CGLineJoin.Miter, layer.miterLimit)
        layer.bounds = CGPathGetBoundingBox(bound)
        layer.position = self.center
        return layer
    }
    */
}


