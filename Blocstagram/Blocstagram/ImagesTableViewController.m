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
#import "MediaTableViewCell.h" // our new custom table cell

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
    
    // register for KVO of mediaItems
    [[DataSource sharedInstance] addObserver:self forKeyPath:@"mediaItems" options:0 context:nil];
    
    // supports pull-to-refresh gesture
    self.refreshControl = [[UIRefreshControl alloc] init]; // UITableVC property
    [self.refreshControl addTarget:self action:@selector(refreshControlDidFire:) forControlEvents:UIControlEventValueChanged];
    
    // UITableViewCell represents a row and at least one cell type must be registered
//    // default table cell
//    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"imageCell"]; // UITableView*Cell* not UITableView
    [self.tableView registerClass:[MediaTableViewCell class] forCellReuseIdentifier:@"mediaCell"]; // new custom cell
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

// best place to remove observers when no longer needed (else may cause crash)
- (void) dealloc {
    [[DataSource sharedInstance] removeObserver:self forKeyPath:@"mediaItems"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Miscellaneous

- (void) refreshControlDidFire:(UIRefreshControl*)sender {
    [[DataSource sharedInstance] requestNewItemsWithCompletionHandler:^(NSError* error) {
        [sender endRefreshing];
    }];
}

// checks if user scrolled to last phto
- (void) infiniteScrollIfNecessary {
    // get cells visible on screen and the last one shown
    NSIndexPath* bottomIndexPath = [[self.tableView indexPathsForVisibleRows] lastObject];
    
    // if cell last image in _mediaItems array, call infiniteScroll method
    if (bottomIndexPath && bottomIndexPath.row == [DataSource sharedInstance].mediaItems.count - 1) {
        [[DataSource sharedInstance] requestOldItemsWithCompletionHandler:nil];
    }
}

// scroll view can be scrolled any way, but table view is locked into vertical-only
// scroll view delegate protocol that's invoked on every scroll direction
- (void) scrollViewDidScroll:(UIScrollView*)scrollView {
    [self infiniteScrollIfNecessary];
}


// all KVO notifications sent to this one method
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void*)context {
    // check 1. is update from registered DataSource object, 2. is mediaItems the updated key?
    if (object == [DataSource sharedInstance] && [keyPath isEqualToString:@"mediaItems"]) {
        // know mediaItems changed; find out what kind of change
        NSKeyValueChange kindOfChange = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
        
        // entire object (_mediaItems) replaced, so reload entire table
        if (kindOfChange == NSKeyValueChangeSetting) {
            [self.tableView reloadData];
        } else if (kindOfChange == NSKeyValueChangeInsertion ||
                   kindOfChange == NSKeyValueChangeRemoval || // incremental changes
                   kindOfChange == NSKeyValueChangeReplacement) {
            // get indexes that changed
            NSIndexSet* indexSetOfChanges = change[NSKeyValueChangeIndexesKey];
            
            // convert index set to array (table view requirement)
            NSMutableArray* indexPathsThatChanged = [NSMutableArray array];
            [indexSetOfChanges enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                NSIndexPath* newIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                [indexPathsThatChanged addObject:newIndexPath];
            }];
            
            // tells table view we're about to make changes
            [self.tableView beginUpdates];
            
            // tell table view what changes are
            if (kindOfChange == NSKeyValueChangeInsertion) {
                [self.tableView insertRowsAtIndexPaths:indexPathsThatChanged withRowAnimation:UITableViewRowAnimationAutomatic];
            } else if (kindOfChange == NSKeyValueChangeRemoval) {
                [self.tableView deleteRowsAtIndexPaths:indexPathsThatChanged withRowAnimation:UITableViewRowAnimationAutomatic];
            } else if (kindOfChange == NSKeyValueChangeReplacement) {
                [self.tableView reloadRowsAtIndexPaths:indexPathsThatChanged withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            
            // tells table view we're done and to complete the animation
            [self.tableView endUpdates];
        }
        
    }
    
}

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
//    // default table cell
//    // take ID string and compare it with roster of registered cells (from viewDidLoad)
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell" forIndexPath:indexPath]; // dequeue returns either brand new or used cell
//    
//    // Configure the cell...
//    
//    static NSInteger imageViewTag = 1234; // just needs to be consistent
//    UIImageView* imageView = (UIImageView*)[cell.contentView viewWithTag:imageViewTag];
//    
//    if (!imageView) {
//        // this is a new cell, it doesn't have an image view yet
//        imageView = [[UIImageView alloc] init];
//        imageView.contentMode = UIViewContentModeScaleToFill; // img stretches to fill UIImageView bounds
//        
//        imageView.frame = cell.contentView.bounds; // so image consumes cell entirety
//        
//        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth; // autoresizing can be none, or hwtrlb
//        
//        imageView.tag = imageViewTag;
//        [cell.contentView addSubview:imageView]; 
//    }
//    
////    // once imageView gotten, set the image (based off cheap model)
////    UIImage* image = self.images[indexPath.row];
////    imageView.image = image;
//    Media* item = [self items][indexPath.row];
//    imageView.image = item.image;
//    // end default table cell
    
    // new custom cell takes care of all the styling and complexity
    MediaTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"mediaCell" forIndexPath:indexPath];
    cell.mediaItem = [DataSource sharedInstance].mediaItems[indexPath.row];
    
    return cell;
}

- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    //return 300; // fixed length still distorts image
//    UIImage* image = self.images[indexPath.row];
//    return image.size.height; // worse as not proportional to screen
    //UIImage* image = self.images[indexPath.row]; // from cheap model
    Media* item = [self items][indexPath.row];
//    UIImage* image = item.image; // for default table cell and new custom cell fixed hack
//    // default table cell
//    return (CGRectGetWidth(self.view.frame) / image.size.width) * image.size.height;
//    // new custom cell (fixed hack not based on actual cell height)
//    return 300 + (CGRectGetWidth(self.view.frame) / image.size.width) * image.size.height;
    // new custom cell ("fake" layout table cell to find height)
    return [MediaTableViewCell heightForMediaItem:item width:CGRectGetWidth(self.view.frame)];
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
        //[DataSource deleteItemAtIndex:indexPath.row]; // real model but not KVO
        //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade]; // by itself, this boilerplate throws runtime internal inconsistency exception; use with cheap or non-KVO model
        
        // KVO deleting from data source
        Media* item = [DataSource sharedInstance].mediaItems[indexPath.row];
        [[DataSource sharedInstance] deleteMediaItem:item]; // calls KVO delete
        //[[DataSource sharedInstance] moveMediaItemToTop:item]; // KVO move2top
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
