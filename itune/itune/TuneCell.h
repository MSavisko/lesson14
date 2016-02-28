//
//  TuneCell.h
//  itune
//
//  Created by Maksym Savisko on 2/28/16.
//  Copyright © 2016 geekhub. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TuneCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *artistName;
@property (weak, nonatomic) IBOutlet UILabel *trackName;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;

@end
