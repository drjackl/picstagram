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
#import "MediaFullScreenViewController.h" // for tap image fullscreens it
#import "CameraViewController.h"

// for fullscreen and camera VCs
@interface ImagesTableViewController () <MediaTableViewCellDelegate, CameraViewControllerDelegate>

//@property (nonatomic) NSMutableArray* images; // default strong, cheap model

// for comment view
@property (nonatomic, weak) UIView* lastSelectedCommentView;
@property (nonatomic) CGFloat lastKeyboardAdjustment;

// must declare since called in this class? no. should've known something silly was making xcode choke
//- (void) downloadIfNeedsImageAtIndexPath:(NSIndexPath*)indexPath; // !!! it's (type)var not (type var)
//- (void) downloadVisibleCells;

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
    
    // for comment view, this mode lets user slide keyboard down like Messages app
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    
    // check if any photo capabilities, and if so, add camera button
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeCamera] ||
        [UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
            
            UIBarButtonItem* cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraPressed:)];
            self.navigationItem.rightBarButtonItem = cameraButton;
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

// override for comment view
- (void) viewWillAppear:(BOOL)animated {
    // don't call super since UITableVC has own keyboard appearance logic
    NSIndexPath* indexPath = self.tableView.indexPathForSelectedRow;
    if (indexPath) { // this we keep from super (ensuring cells deselected)
        [self.tableView deselectRowAtIndexPath:indexPath animated:animated];
    }
}

// override for comment view
- (void) viewWillDisappear:(BOOL)animated {
    // don't call super since UITableVC has own keyboard appearance logic
    
}

// best place to remove observers when no longer needed (else may cause crash)
- (void) dealloc {
    [[DataSource sharedInstance] removeObserver:self forKeyPath:@"mediaItems"];
    
    // for comment view
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Camera and CameraViewControllerDelegate

// target method of camera button
- (void) cameraPressed:(UIBarButtonItem*)sender {
    CameraViewController* cameraVC = [[CameraViewController alloc] init];
    cameraVC.delegate = self;
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:cameraVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void) cameraViewController:(CameraViewController*)cameraViewController didCompleteWithImage:(UIImage*)image {
    [cameraViewController dismissViewControllerAnimated:YES completion:^{
        if (image) {
            NSLog(@"Got an image!");
        } else {
            NSLog(@"Closed without an image");
        }
    }];
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

    
    // print out deceleration rates
    
    //NSLog(@"did scroll");

    // also always seems to be 0.998
    //NSLog(@"scrollview Decelerating at rate: %f", [scrollView decelerationRate]);

//    // always seems to be fast and at 0.998
//    CGFloat decelerationRate = [scrollView decelerationRate];
//    if (decelerationRate >= UIScrollViewDecelerationRateFast) {
//        NSLog(@"Fast decelerating: %f", decelerationRate);
//    } else if (decelerationRate >= UIScrollViewDecelerationRateNormal) {
//        NSLog(@"Normal decelerating: %f", decelerationRate);
//    } else {
//        NSLog(@"Slow decelerating?: %f", decelerationRate);
//    }
//    
//    NSLog(@"Dragging? %@", scrollView.dragging ? @"YES" : @"NO");
}

// also see scrollViewDidScroll
- (void) scrollViewWillBeginDecelerating:(UIScrollView*)scrollView {
    [self downloadVisibleCells];
    
    // these are both always the same and at 0.998
//    NSLog(@"table Decelerating at rate: %f", [self.tableView decelerationRate]);
//    NSLog(@"scrollview Decelerating at rate: %f", [scrollView decelerationRate]);

}

// goes through all visible cells and downloads if needs image
- (void) downloadVisibleCells {
    NSArray* visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath* indexPath in visibleIndexPaths) {
        [self downloadIfNeedsImageAtIndexPath:indexPath];
    }
}

// extracted originally from tableView:willDisplayCell:
// downloads only if needs image
- (void) downloadIfNeedsImageAtIndexPath:(NSIndexPath*) indexPath {
    Media* media = [DataSource sharedInstance].mediaItems[indexPath.row]; // weird couldn't autocomplete .row (forgot the . after mediaItems)
    if (media.downloadState == MediaDownloadStateNeedsImage) {
        [[DataSource sharedInstance] downloadImageForMediaItem:media];
    }
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

#pragma mark - Keyboard Handling

- (void) keyboardWillShow:(NSNotification*)notification {
    // get keyboard fram within self.view's coordinate system
    NSValue* frameValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameInScreenCoordinates = frameValue.CGRectValue;
    CGRect keyboardFrameInViewCoordinates = [self.navigationController.view convertRect:keyboardFrameInScreenCoordinates fromView:nil];
    
    // get comment view frame in same coordinate system
    CGRect commentViewFrameInViewCoordinates = [self.navigationController.view convertRect:self.lastSelectedCommentView.bounds fromView:self.lastSelectedCommentView];
    
    CGFloat keyboardY = CGRectGetMinY(keyboardFrameInViewCoordinates);
    CGFloat commentViewY = CGRectGetMinY(commentViewFrameInViewCoordinates);
    CGFloat difference = commentViewY - keyboardY;
    
    CGFloat heightToScroll = 0; // height to scroll starts at zero
    if (difference > 0) { // positive if keyboard below comment view
        heightToScroll += difference; // add difference to make even
    }
    
    if (CGRectIntersectsRect(keyboardFrameInViewCoordinates, commentViewFrameInViewCoordinates)) {
        CGRect intersectionRect = CGRectIntersection(keyboardFrameInViewCoordinates, commentViewFrameInViewCoordinates);
        heightToScroll += CGRectGetHeight(intersectionRect);
    }

    if (heightToScroll > 0) {
        CGPoint contentOffset = self.tableView.contentOffset;
        UIEdgeInsets contentInsets = self.tableView.contentInset;
        UIEdgeInsets scrollIndicatorInsets = self.tableView.scrollIndicatorInsets;
        
        contentInsets.bottom += heightToScroll;
        scrollIndicatorInsets.bottom += heightToScroll;
        contentOffset.y += heightToScroll;
        
        NSNumber* durationNumber = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
        NSNumber* curveNumber = notification.userInfo[UIKeyboardAnimationCurveUserInfoKey];
        
        NSTimeInterval duration = durationNumber.doubleValue;
        UIViewAnimationCurve curve = curveNumber.unsignedIntegerValue;
        UIViewAnimationOptions options = curve << 16;
        
        [UIView animateWithDuration:duration delay:0 options:options
                         animations:^{
            self.tableView.contentInset = contentInsets;
            self.tableView.scrollIndicatorInsets = scrollIndicatorInsets;
            self.tableView.contentOffset = contentOffset;
                         } completion:nil];
    }
    
    self.lastKeyboardAdjustment = heightToScroll;
}

// keyboard hide is reversing show method
- (void) keyboardWillHide:(NSNotification*)notification {
    UIEdgeInsets contentInsets = self.tableView.contentInset;
    contentInsets.bottom -= self.lastKeyboardAdjustment;
    
    UIEdgeInsets scrollIndicatorInsets = self.tableView.scrollIndicatorInsets;
    scrollIndicatorInsets.bottom -= self.lastKeyboardAdjustment;
    
    NSNumber* durationNumber = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    NSNumber* curveNumber = notification.userInfo[UIKeyboardAnimationCurveUserInfoKey];
    
    NSTimeInterval duration = durationNumber.doubleValue;
    UIViewAnimationCurve curve = curveNumber.unsignedIntegerValue;
    UIViewAnimationOptions options = curve << 16;
    
    [UIView animateWithDuration:duration delay:0 options:options
                     animations:^{
                         self.tableView.contentInset = contentInsets;
                         self.tableView.scrollIndicatorInsets = scrollIndicatorInsets;
                     } completion:nil];
}

#pragma mark - MediaTableViewCellDelegate

- (void) cell:(MediaTableViewCell*)cell didTapImageView:(UIImageView*)imageView {
    MediaFullScreenViewController* fullScreenVC = [[MediaFullScreenViewController alloc] initWithMedia:cell.mediaItem];
    
    [self presentViewController:fullScreenVC animated:YES completion:nil];
}

- (void) cell:(MediaTableViewCell*)cell didLongPressImageView:(UIImageView*)imageView {
//    NSMutableArray* itemsToShare = [NSMutableArray array];
//    
//    if (cell.mediaItem.caption.length > 0) {
//        [itemsToShare addObject:cell.mediaItem.caption];
//    }
//    
//    if (cell.mediaItem.image) {
//        [itemsToShare addObject:cell.mediaItem.image];
//    }
//    
//    if (itemsToShare.count > 0) {
//        UIActivityViewController* activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
//        [self presentViewController:activityVC animated:YES completion:nil];
//    }
    
    [cell.mediaItem shareGivenViewController:self];
}

- (void) cell:(MediaTableViewCell*)cell didTwoFingerTapImageView:(UIImageView*)imageView {
    NSLog(@"Two finger tap heard");
    [[DataSource sharedInstance] retryDownloadingMediaItem:cell.mediaItem];
}

// setting cell.mediaItem will update button's appearance which we always do in end
- (void) cellDidPressLikeButton:(MediaTableViewCell*)cell {
    Media* item = cell.mediaItem;
    
    [[DataSource sharedInstance] toggleLikeOnMediaItem:item withCompletionHandler:^{
        if (cell.mediaItem == item) { // important to check cuz cells get reloaded
            cell.mediaItem = item;
        }
    }];
    
    cell.mediaItem = item;
}

// comment view related delegate methods: if start composing, store view reference
- (void) cellWillStartComposingComment:(MediaTableViewCell*)cell {
    self.lastSelectedCommentView = (UIView*)cell.commentView;
}

// comment view related delegate methods: if button press, upload comment via API
- (void) cell:(MediaTableViewCell*)cell didComposeComment:(NSString*)comment {
    [[DataSource sharedInstance] commentOnMediaitem:cell.mediaItem withCommentText:comment];
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
//    // initial table cell
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
//    // end initial table cell
    
    // new custom cell takes care of all the styling and complexity
    MediaTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"mediaCell" forIndexPath:indexPath];
    
    cell.delegate = self; // fullscreen: set delegate whenever create/dequeue a cell
    
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

// overriding avoids table view calculating every cell height, just when scrolled in
// auto-layout computationally expensive; else UI freezes a bit in infinite scroll
- (CGFloat) tableView:(UITableView*)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath*)indexPath {
    Media* item = [DataSource sharedInstance].mediaItems[indexPath.row];
    if (item.image) {
        return 450;//350; // minimize jerky scrolling for comment view
    } else {
        return 250;//150; // minimize jerky scrolling for comment view
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

// if row tapped, assume user doesn't want keyboard
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    MediaTableViewCell* cell = (MediaTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    [cell stopComposingComment];
}

// for redownloading images: instead of downloading images as we get media items,
// check if need images right before display
- (void) tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    // original checkpoint code extracted
    //[self downloadIfNeedsImageAtIndexPath:indexPath]; // weird didn't autocomplete method after defining
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
