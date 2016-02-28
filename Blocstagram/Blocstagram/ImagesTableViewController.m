//
//  ImagesTableViewController.m
//  Blocstagram
//
//  Created by Jack Li on 2/27/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "ImagesTableViewController.h"
#import "DataSource.h" // for our Model
#import "User.h"
#import "Media.h"
#import "Comment.h"

@interface ImagesTableViewController ()

//@property (nonatomic) NSMutableArray* images; // default strong, cheap model

@end

@implementation ImagesTableViewController

- (id) initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // custom initialization
        //self.images = [NSMutableArray array]; // cheap model
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    // populate (cheap model) after initializing array
//    for (int i = 1; i <= 10; i++) {
//        NSString* imageName = [NSString stringWithFormat:@"%d.jpg", i];
//        UIImage* image = [UIImage imageNamed:imageName];
//        if (image) {
//            [self.images addObject:image];
//        }
//    }
    
    // UITableViewCell represents a row and at least one cell type must be registered
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"imageCell"]; // UITableView*Cell* not UITableView
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Miscellaneous

// convenience method
- (NSArray*) items {
    return [DataSource sharedInstance].mediaItems;
}

#pragma mark - Table view data source

// can delete since the default returns 1, which we want
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
//    return 0;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
//    return 0;
    //return self.images.count; // our 10 images (from cheap model)
    return [self items].count; // real model
}

// most important method: content, image and accessory views all customizable here
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // take ID string and compare it with roster of registered cells (from viewDidLoad)
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell" forIndexPath:indexPath]; // dequeue returns either brand new or used cell
    
    // Configure the cell...
    
    static NSInteger imageViewTag = 1234; // just needs to be consistent
    UIImageView* imageView = (UIImageView*)[cell.contentView viewWithTag:imageViewTag];
    
    if (!imageView) {
        // this is a new cell, it doesn't have an image view yet
        imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleToFill; // img stretches to fill UIImageView bounds
        
        imageView.frame = cell.contentView.bounds; // so image consumes cell entirety
        
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth; // autoresizing can be none, or hwtrlb
        
        imageView.tag = imageViewTag;
        [cell.contentView addSubview:imageView]; 
    }
    
//    // once imageView gotten, set the image (based off cheap model)
//    UIImage* image = self.images[indexPath.row];
//    imageView.image = image;
    Media* item = [self items][indexPath.row];
    imageView.image = item.image;
    
    return cell;
}

- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    //return 300; // fixed length still distorts image
//    UIImage* image = self.images[indexPath.row];
//    return image.size.height; // worse as not proportional to screen
    //UIImage* image = self.images[indexPath.row]; // from cheap model
    Media* item = [self items][indexPath.row];
    UIImage* image = item.image;
    return (CGRectGetWidth(self.view.frame) / image.size.width) * image.size.height;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) { // if user swipes left
        // Delete the row from the data source
        //[self.images removeObjectAtIndex:indexPath.row]; // cheap model
        [DataSource deleteItemAtIndex:indexPath.row]; // real model
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade]; // by itself, this boilerplate throws runtime internal inconsistency exception
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
