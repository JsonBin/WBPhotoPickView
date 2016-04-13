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
                    // 采用子线程获取图片，加快读取速度
                    let group=dispatch_group_create()
                    let queue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                    dispatch_group_async(group, queue, { 
                        for index in 0..<asarray.count {
                            manage.requestImageForAsset((asarray[index] as! PHAsset), targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.Default, options: options, resultHandler: { (image, dic) in
                                im_array.addObject(image!)
                            })
                        }
                    })
                    dispatch_group_notify(group, queue, {
                        if im_array.count>0 {
                            weakSelf?.nameArray.addObject(collect.localizedTitle!)
                            weakSelf?.imageArray.addObject(im_array)
                            dispatch_async(dispatch_get_main_queue(), {
                                weakSelf?.tableView.reloadData()
                            })
                        }
                    })
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
    private var indexPathArray=NSMutableArray()
    
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
        // 强制取消刷新时重用机制出错的问题
        if !indexPathArray.containsObject(indexPath) {
            cell.button.selected=false
            cell.selectShaplayer.fillColor=UIColor.whiteColor().CGColor
            cell.mask.removeFromSuperview()
        }else{
            cell.button.selected=true
            cell.selectShaplayer.fillColor=UIColor.greenColor().CGColor
            cell.contentView.insertSubview(cell.mask, aboveSubview: cell.imageView)
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
                    weakSelf?.warnlabel("最多能选择 \(NSString.init(format: "%ld", (weakSelf?.photoCount)!) as String) 张照片!")
                }else{
                    weakSelf?.selectArray.addObject((weakSelf?.array[indexPath.row])!)
                    weakSelf?.indexPathArray.addObject(indexPath)
                }
            }else{
                if weakSelf?.selectArray.count>0{
                    weakSelf?.selectArray.removeObject((weakSelf?.array[indexPath.row])!)
                    weakSelf?.indexPathArray.removeObject(indexPath)
                }
            }
        }
        return cell
    }
    
    private func warnlabel(string:NSString)->Void{
        let label=UILabel()
        let win=UIApplication.sharedApplication().keyWindow!
        label.bounds=CGRectMake(0, 0, win.bounds.size.width/2+40, 20)
        label.center=win.center
        label.textAlignment = .Center
        label.layer.cornerRadius=2
        label.text=string as String
        label.font=UIFont.systemFontOfSize(15)
        label.textColor=UIColor.whiteColor()
        label.backgroundColor=UIColor ( red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8 )
        win.addSubview(label)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) {
            label.removeFromSuperview()
        }
    }
    
    // 偏移，上 10 左 1 下 0 右 1
    internal func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10, 1, 0, 1)
    }
    
    //MARK: UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        weak var weakself=self
        if allowEditing {       // 查看照片
            let scanView=scanPhoto()
            scanView.array=array
            scanView.indexArray=indexPathArray
            scanView.count=photoCount
            let oldArray:NSArray=indexPathArray.mutableCopy() as! NSArray
            // 查看照片选择回调
            scanView.selectIndexPathArray({ (poarray) in
                // 如果选择的照片还未选过，则添加，否则不添加,若没有，则删除
                // 删除原始数据
                weakself?.selectArray.removeAllObjects()
                for i in 0..<oldArray.count {
                    // 删除所有数据
                    let cell:WBPhotoSelectViewCell=collectionView.cellForItemAtIndexPath(oldArray[i]  as! NSIndexPath) as! WBPhotoSelectViewCell
                    cell.button.selected=false
                    cell.selectShaplayer.fillColor=UIColor.whiteColor().CGColor
                    cell.mask.removeFromSuperview()
                }
                // 添加新数据
                for index in 0..<poarray.count{
                    // 添加新数据
                    let row=(poarray[index] as! NSIndexPath).row
                    weakself?.selectArray.addObject((weakself?.array[row])!)  // 添加新数据
                    let cell:WBPhotoSelectViewCell=collectionView.cellForItemAtIndexPath(poarray[index]  as! NSIndexPath) as! WBPhotoSelectViewCell
                    cell.button.selected=true
                    cell.selectShaplayer.fillColor=UIColor.greenColor().CGColor
                    cell.contentView.insertSubview(cell.mask, aboveSubview: cell.imageView)
                }
               self.indexPathArray=poarray  // 重新赋值数组
            })
            scanView.showPhoto()
            scanView.transform=CGAffineTransformMakeScale(0.001, 0.001)
            scanView.scollec!.scrollToItemAtIndexPath(NSIndexPath.init(forRow: indexPath.row, inSection: 0), atScrollPosition: .None, animated: false)
            UIView.animateWithDuration(0.2, animations: { 
                scanView.transform=CGAffineTransformIdentity
            })
        }
    }
}

// 自定义cell
class WBPhotoSelectViewCell: UICollectionViewCell {
    
    internal var imageView=UIImageView()
    // 回调indexPath，照片加入数组
    internal var index:((flag:Bool)->Void)?
    internal let button=UIButton()
    internal let mask=UIView()
    internal let selectShaplayer=CAShapeLayer()
    
    private let selectLayer=CALayer()
    
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
        selectLayer.backgroundColor = UIColor ( red: 0.4, green: 0.4, blue: 0.4, alpha: 0.5 ).CGColor
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
        button.selected=false
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

// 查看照片
class scanPhoto: UIView , UICollectionViewDelegate, UICollectionViewDataSource{
    
    internal var array:NSArray?
    internal var count:NSInteger?
    internal var photoIndexArray:((poarray:NSMutableArray)->Void)?
    
    private var win:UIWindow?
    private var scollec:UICollectionView?
    private var indexArray=NSMutableArray() // 记录选取照片的indexPath
    
    internal func showPhoto()->Void{
        win=UIApplication.sharedApplication().keyWindow
        self.backgroundColor=UIColor ( red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7 )
        self.frame=win!.bounds
        createCollection()
        self.center=win!.center
        win!.addSubview(self)
    }
    
    internal func selectIndexPathArray(photoarray:(poarray:NSMutableArray)->Void)->Void{
        photoIndexArray=photoarray
    }
    
    private func createCollection() -> Void {
        let flow=UICollectionViewFlowLayout()
        flow.minimumLineSpacing=0
        flow.minimumInteritemSpacing=0
        flow.itemSize=CGSizeMake(self.bounds.width, self.bounds.height)
        flow.scrollDirection = .Horizontal
        scollec=UICollectionView.init(frame: self.bounds, collectionViewLayout: flow)
        scollec!.backgroundColor=UIColor.clearColor()
        scollec!.pagingEnabled=true
        scollec!.bounces=true
        scollec!.showsVerticalScrollIndicator=false
        scollec!.delegate=self
        scollec!.dataSource=self
        scollec!.registerClass(scanPhotoCell.classForKeyedArchiver(), forCellWithReuseIdentifier: "scanCell")
        self.addSubview(scollec!)
        
        let bgView=UIView()
        bgView.frame=CGRectMake(0, self.bounds.height-40, self.bounds.width, 40)
        bgView.backgroundColor=UIColor ( red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5 )
        self.addSubview(bgView)
        
        let cancle=UIButton.init(type: .System)
        cancle.frame=CGRectMake(0, 0, 60, 40)
        cancle.setTitle("取消", forState: .Normal)
        cancle.backgroundColor=UIColor.clearColor()
        cancle.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        cancle.addTarget(self, action: #selector(scanPhoto.cancle), forControlEvents: .TouchUpInside)
        bgView.addSubview(cancle)
        
        let done=UIButton.init(type: .System)
        done.frame=CGRectMake(self.frame.size.width-60, 0, 60, 40)
        done.setTitle("完成", forState: .Normal)
        done.backgroundColor=UIColor.clearColor()
        done.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        done.addTarget(self, action: #selector(scanPhoto.done), forControlEvents: .TouchUpInside)
        bgView.addSubview(done)
    }
    
    internal func cancle()->Void{
        UIView.animateWithDuration(0.2, animations: {
            self.transform=CGAffineTransformMakeScale(0.0001, 0.0001)
        }) { (flag) in
            self.removeFromSuperview()
        }
        self.removeFromSuperview()
    }
    
    internal func done()->Void{
        // 回调选择好的照片
        if (photoIndexArray != nil) {
            photoIndexArray!(poarray: indexArray)
        }
        cancle()
    }
    
    //MARK: UICollectionViewDelegate, UICollectionViewDataSource
    internal func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return array!.count
    }
    
    internal func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell:scanPhotoCell=collectionView.dequeueReusableCellWithReuseIdentifier("scanCell", forIndexPath: indexPath) as! scanPhotoCell
        var image:UIImage?
        if #available(iOS 8.0, *) {
            image=array![indexPath.row] as? UIImage
        }else{
            image=UIImage.init(CGImage: array![indexPath.row] as! CGImage)
        }
        let height=image!.size.height*self.bounds.width/image!.size.width
        if height<self.bounds.height {
            cell.imageView.bounds=CGRectMake(0, 0, self.bounds.width, height)
        }else{
            cell.imageView.bounds=CGRectMake(0, 0, image!.size.width/image!.size.height*self.bounds.height, self.bounds.height)
        }
        cell.imageView.image=image
        // 选择了照片再查看,取消出现混乱选择的情况
        if indexArray.containsObject(indexPath){
            cell.selectImage(true)
        }else{
            cell.selectImage(false)
        }
        return cell
    }
    
    internal func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell:scanPhotoCell=collectionView.cellForItemAtIndexPath(indexPath) as! scanPhotoCell
        if indexArray.containsObject(indexPath) {
            indexArray.removeObject(indexPath)
            cell.selectImage(false)
        }else{
            if indexArray.count>count!-1 {
                warnlabel("最多能选择 \(NSString.init(format: "%ld", count!) as String) 张照片!")
            }else{
                indexArray.addObject(indexPath)
                cell.selectImage(true)
            }
        }
    }
    
    private func warnlabel(string:NSString)->Void{
        let label=UILabel()
        let win=UIApplication.sharedApplication().keyWindow!
        label.bounds=CGRectMake(0, 0, win.bounds.size.width/2+40, 20)
        label.center=win.center
        label.textAlignment = .Center
        label.layer.cornerRadius=2
        label.text=string as String
        label.font=UIFont.systemFontOfSize(15)
        label.textColor=UIColor.whiteColor()
        label.backgroundColor=UIColor ( red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8 )
        win.addSubview(label)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) {
            label.removeFromSuperview()
        }
    }
}

class  scanPhotoCell: UICollectionViewCell {
    internal var imageView=UIImageView()
    
    private let mask=UIView()
    private let selectLayer=CALayer()
    private let selectShaplayer=CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.frame=self.bounds
        self.contentView.addSubview(imageView)
        
        selectLayer.position = self.contentView.center
        selectLayer.cornerRadius=25
        selectLayer.bounds = CGRectMake(0, 0, 50, 50)
        selectLayer.backgroundColor = UIColor ( red: 0.4, green: 0.4, blue: 0.4, alpha: 0.5 ).CGColor
        
        let path  = UIBezierPath()
        path.moveToPoint(CGPointMake(20, 22))
        path.addLineToPoint(CGPointMake(25, 26))
        path.addLineToPoint(CGPointMake(32, 18))
        path.addLineToPoint(CGPointMake(34, 20))
        path.addLineToPoint(CGPointMake(25, 30))
        path.addLineToPoint(CGPointMake(18, 24))
        path.closePath()
        
        selectShaplayer.path = path.CGPath
        selectShaplayer.lineWidth = 0.8
        selectShaplayer.strokeColor=UIColor.clearColor().CGColor
        selectShaplayer.fillColor = UIColor.whiteColor().CGColor
        layer.position = self.center
        selectLayer.addSublayer(selectShaplayer)
        
        mask.frame=self.bounds
        mask.backgroundColor=UIColor ( red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4 )
        
    }
    
    internal func selectImage(falg:Bool)->Void{
        
        if falg {
            selectShaplayer.fillColor=UIColor.greenColor().CGColor
            self.contentView.layer.addSublayer(selectLayer)
            self.contentView.insertSubview(mask, aboveSubview: imageView)
        }else{
            selectShaplayer.fillColor = UIColor.whiteColor().CGColor
            mask.removeFromSuperview()
            selectLayer.removeFromSuperlayer()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}


