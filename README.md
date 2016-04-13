# WBPhotoPickView
Swift 写的基于相册的多项照片选择器，实现自定义选择照片张数，以及照片是否可放大

使用方法
=======

        // 初始化
        let  v = WBPhotoPickView()
        // 设置属性(可设置，可不设置)
        v.allowEditing = true  // 设置照片是否可查看编辑(默认false)
        v.photoCount=4 // 设置需要选取的照片数量（默认最多能选取 5 张）
        
        // 返回照片的结果数组，格式为UIImage
        v.selectPhoto { (photo) in
            print("最后选择的照片是:\(photo)")
        }
        self.presentViewController(UINavigationController.init(rootViewController:v), animated: true, completion: nil)

效果图
========

 ![gif](https://github.com/JsonBin/WBPhotoPickView/raw/master/photo1.gif "自定义照片多选器")
