//
//  ViewController.swift
//  WBPhotoPickView
//
//  Created by Zwb on 16/4/12.
//  Copyright © 2016年 zwb. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.title="WBPhotoPickView"
        
        let button=UIButton.init(type: .System)
        button.frame=CGRectMake(width()/2-20, height()/2-20, 40, 40)
        button.setTitle("选择", forState: .Normal)
        button.addTarget(self, action: #selector(self.buttonClick), forControlEvents: .TouchUpInside)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.backgroundColor=UIColor.blueColor()
        self.view.addSubview(button)
    }
    
    internal func buttonClick()->Void{
        
        let  v = WBPhotoPickView()
        // 设置属性(可设置，可不设置)
        v.allowEditing = true  // 设置照片是否可查看编辑(默认false)
        v.photoCount=4 // 设置需要选取的照片数量（默认最多能选取 5 张）
        
        v.selectPhoto { (photo) in
            print("最后选择的照片是:\(photo)")
        }
        self.presentViewController(UINavigationController.init(rootViewController:v), animated: true, completion: nil)
    }
    
    private func width()->CGFloat{
        return self.view.bounds.size.width
    }
    
    private func height()->CGFloat{
        return self.view.bounds.size.height
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

