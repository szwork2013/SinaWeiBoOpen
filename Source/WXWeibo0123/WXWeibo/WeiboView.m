//
//  WeiboView.m
//  WXWeibo
//
//  Created by wei.chen on 13-1-23.
//  Copyright (c) 2013年 www.iphonetrain.com 无限互联3G学院. All rights reserved.
//

#import "WeiboView.h"
#import "UIFactory.h"
#import "WeiboModel.h"
#import "UIImageView+WebCache.h"
#import "ThemeImageView.h"
#import "RegexKitLite.h"
#import "UIUtils.h"
#import "HomeViewController.h"
#import "UserViewController.h"
#import "WebViewController.h"

#define LIST_FONT   14.0f           //列表中文本字体
#define LIST_REPOST_FONT  13.0f;    //列表中转发的文本字体
#define DETAIL_FONT  18.0f          //详情的文本字体
#define DETAIL_REPOST_FONT 17.0f    //详情中转发的文本字体

@implementation WeiboView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _initView];
        _parseText=[[NSMutableString alloc] init];
    }
    return self;
}

//初始化子视图
- (void)_initView {
    //微博内容
    _textLabel = [[RTLabel alloc] initWithFrame:CGRectZero];
    _textLabel.delegate = self;
    _textLabel.font = [UIFont systemFontOfSize:14.0f];
    //十进制RGB值：r:69 g:149 b:203
    //十六进制RGB值：4595CB
    //设置链接的颜色
    _textLabel.linkAttributes = [NSDictionary dictionaryWithObject:@"#4595CB" forKey:@"color"];
    //设置链接高亮的颜色
    _textLabel.selectedLinkAttributes = [NSDictionary dictionaryWithObject:@"darkGray" forKey:@"color"];
    [self addSubview:_textLabel];
    
    //微博图片
    _image = [[UIImageView alloc] initWithFrame:CGRectZero];
    _image.backgroundColor = [UIColor clearColor];
    _image.image = [UIImage imageNamed:@"page_image_loading.png"];
    //设置图片的内容显示模式：等比例缩/放（不会被拉伸或压缩）
    _image.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_image];
    
    //转发微博视图的背景
    _repostBackgroudView = [UIFactory createImageView:@"timeline_retweet_background.png"];
    UIImage *image = [_repostBackgroudView.image stretchableImageWithLeftCapWidth:25 topCapHeight:10];
    _repostBackgroudView.image = image;
    _repostBackgroudView.leftCapWidth = 25;
    _repostBackgroudView.topCapHeight = 10;
    _repostBackgroudView.backgroundColor = [UIColor clearColor];
    [self insertSubview:_repostBackgroudView atIndex:0];
    
}

- (void)setWeiboModel:(WeiboModel *)weiboModel {
    if (_weiboModel != weiboModel) {
        [_weiboModel release];
        _weiboModel = [weiboModel retain];
    }
    
    //创建转发微博视图
    if (_repostView == nil) {
        _repostView = [[WeiboView alloc] initWithFrame:CGRectZero];
        _repostView.isRepost = YES;
        _repostView.isDetail=self.isDetail;
        
        [self addSubview:_repostView];        
    }
    //
    
    [self parseLink];
}

-(void) parseLink{
    [_parseText setString:@""];
    
    if (_isRepost) {
        NSString *nickName=_weiboModel.user.screen_name;
        NSString *encodeName=[nickName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ;
        
        [_parseText appendFormat:@"<a href='user://@%@'>@%@</a>:",encodeName,nickName];
        
      
    }
    
    
    NSString *text=_weiboModel.text;
    NSString *reg=@"(@\\w+)";
    NSString *huti=@"#\\w+#";
    NSString *http=@"(http(s)?://([A-Za-z0-9._-]+(/)?)*)";
    NSString *all=@"(@\\w+)|(#\\w+#)|(http(s)?://([A-Za-z0-9._-]+(/)?)*)";
    
    NSArray* array= [text componentsMatchedByRegex:all];
    for (NSString*s in array ) {
        
        NSString *url=@"";
        
        NSString * encodingString = [s stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        if( [s hasPrefix:@"@"]){
          url=[NSString stringWithFormat:@"<a href='user://%@'>%@</a>",encodingString,s];
           
        }else if([s hasPrefix:@"#"]){
           url=[NSString stringWithFormat:@"<a href='topic://%@'>%@</a>",encodingString,s];
        }else if( [s hasPrefix:@"http"]){
          url=[NSString stringWithFormat:@"<a href='%@'>%@</a>",encodingString,s];

        }
        text=  [text stringByReplacingOccurrencesOfString:s withString:url];
       
    }

    [_parseText appendString:text];
    
}

-(void) _renderText{
    //---------------微博内容_textLabel子视图------------------
    //获取字体大小
    float fontSize = [WeiboView getFontSize:self.isDetail isRepost:self.isRepost];
    _textLabel.font = [UIFont systemFontOfSize:fontSize];
    _textLabel.frame = CGRectMake(0, 0, self.width, 20);
    //判断当前视图是否为转发视图
    if (self.isRepost) {
        _textLabel.frame = CGRectMake(10, 10, self.width-20, 0);
    }
    _textLabel.text = _parseText;
    //文本内容尺寸
    CGSize textSize = _textLabel.optimumSize;
    _textLabel.height = textSize.height;
}
-(void) _renderSourceWeibView{
    WeiboModel *repostWeibo = _weiboModel.relWeibo;
    if (repostWeibo != nil) {
        _repostView.hidden = NO;
        _repostView.weiboModel = repostWeibo;
        
        //计算转发微博视图的高度
        float height = [WeiboView getWeiboViewHeight:repostWeibo isRepost:YES isDetail:self.isDetail];
        _repostView.frame = CGRectMake(0, _textLabel.bottom, self.width, height);
    } else {
        _repostView.hidden = YES;
    }
}
-(void) _renderImage{
    
    
    
    
    if (self.isDetail) {
        //中等图
        NSString *thumbnailImage = _weiboModel.bmiddleImage;
        if (thumbnailImage != nil && ![@"" isEqualToString:thumbnailImage]) {
            _image.hidden = NO;
            _image.frame = CGRectMake(10, _textLabel.bottom+10, 280, 200);
            
            //加载网络图片数据
            [_image setImageWithURL:[NSURL URLWithString:thumbnailImage]];
        } else {
            _image.hidden = YES;
        }
    }else{
        //判断是大图还是小图
        int mode= [[NSUserDefaults standardUserDefaults] integerForKey:kBrowMode];
        if (mode==smallBrowMode) {
            NSString *thumbnailImage = _weiboModel.thumbnailImage;
            if (thumbnailImage != nil && ![@"" isEqualToString:thumbnailImage]) {
                _image.hidden = NO;
                _image.frame = CGRectMake(10, _textLabel.bottom+10, 70, 80);
                
                //加载网络图片数据
                [_image setImageWithURL:[NSURL URLWithString:thumbnailImage]];
            } else {
                _image.hidden = YES;
            }
        }else if(mode==LargeBrowMode){
            //取大图
            NSString *thumbnailImage = _weiboModel.bmiddleImage;
            if (thumbnailImage != nil && ![@"" isEqualToString:thumbnailImage]) {
                _image.hidden = NO;
                _image.frame = CGRectMake(10, _textLabel.bottom+10, self.width-20, 180);
                
                //加载网络图片数据
                [_image setImageWithURL:[NSURL URLWithString:thumbnailImage]];
            } else {
                _image.hidden = YES;
            }
        }
    
    }
    
}

//layoutSubviews 展示数据、子视图布局
- (void)layoutSubviews {
    [super layoutSubviews];
    //加载文本
    [self _renderText];
    
    //---------------转发的微博视图_repostView------------------
    //转发的微博model
    [self _renderSourceWeibView];
    
    //---------------微博图片视图_image------------------
    [self _renderImage];
    
    //----------------转发的微博视图背景_repostBackgroudView---------------
    if (self.isRepost) {
        _repostBackgroudView.frame = self.bounds;
        _repostBackgroudView.hidden = NO;
    } else {
        _repostBackgroudView.hidden = YES;
    }
    
}

#pragma mark - 计算
//获取字体大小
+ (float)getFontSize:(BOOL)isDetail isRepost:(BOOL)isRepost {
    float fontSize = 14.0f;
    
    if (!isDetail && !isRepost) {
        return LIST_FONT;
    }
    else if(!isDetail && isRepost) {
        return LIST_REPOST_FONT;
    }
    else if(isDetail && !isRepost) {
        return DETAIL_FONT;
    }
    else if(isDetail && isRepost) {
        return DETAIL_REPOST_FONT;
    }
    
    return fontSize;
}

//计数微博视图的高度
+ (CGFloat)getWeiboViewHeight:(WeiboModel *)weiboModel
                     isRepost:(BOOL)isRepost
                     isDetail:(BOOL)isDetail {
    /**
     *   实现思路：计算每个子视图的高度，然后相加。
     **/
    float height = 0;
    
    //--------------------计算微博内容text的高度------------------------
    RTLabel *textLabel = [[RTLabel alloc] initWithFrame:CGRectZero];
    float fontsize = [WeiboView getFontSize:isDetail isRepost:isRepost];
    textLabel.font = [UIFont systemFontOfSize:fontsize];
    //判断此微博是否显示在详情页面
    if (isDetail) {
        textLabel.width = kWeibo_Width_Detail;
    } else {
        textLabel.width = kWeibo_Width_List;
    }
    
    NSString *weiboText=nil;
    if (isRepost) {
        textLabel.width-=20;
        NSString *nickName=weiboModel.user.screen_name;
        weiboText=[NSString stringWithFormat:@"%@:%@",nickName,weiboModel.text];
    }else{
        weiboText=weiboModel.text;
    }
    
    textLabel.text = weiboText;
    
    height += textLabel.optimumSize.height;
    
    //--------------------计算微博图片的高度------------------------
    if (isDetail) {
        NSString *thumbnailImage = weiboModel.bmiddleImage;
        if (thumbnailImage != nil && ![@"" isEqualToString:thumbnailImage]) {
            height += (200+10);
        }
    }else{
        int mode= [[NSUserDefaults standardUserDefaults] integerForKey:kBrowMode];
        if (mode==smallBrowMode) {
            
            NSString *thumbnailImage = weiboModel.thumbnailImage;
            if (thumbnailImage != nil && ![@"" isEqualToString:thumbnailImage]) {
                height += (80+10);
            }
        }else if (mode==LargeBrowMode){
            
            NSString *thumbnailImage = weiboModel.bmiddleImage;
            if (thumbnailImage != nil && ![@"" isEqualToString:thumbnailImage]) {
                height += (180+10);
            }
        }
        
     
    }
   
    
    //--------------------计算转发微博视图的高度------------------------
    //转发的微博
    WeiboModel *relWeibo = weiboModel.relWeibo;
    if (relWeibo != nil) {
        //转发微博视图的高度
        float repostHeight = [WeiboView getWeiboViewHeight:relWeibo isRepost:YES isDetail:isDetail];
        height += (repostHeight);
    }
    
    if (isRepost == YES) {
        height += 30;
    }
    
    return height;
}


#pragma mark - RTLabel delegate
- (void)rtLabel:(id)rtLabel didSelectLinkWithURL:(NSURL*)url {
   
    NSString *u=[url absoluteString];
    NSString *str = [u stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    if ([str hasPrefix:@"user"]) {
       
        UserViewController *view=[[UserViewController alloc] init];
        view.userName=str;
        NSLog(@"%@",str);
        
        [self.viewController.navigationController pushViewController:view animated:YES];
        
        
        
        
    }else if ( [str hasPrefix:@"topic"]){
        NSLog(@"话题");
    }else if( [str hasPrefix:@"http"]){
        
        
        WebViewController *webView=[[WebViewController alloc] initWithUrl:str];
        
        [self.viewController.navigationController pushViewController:webView animated:YES];
        
        
        
    }
  
    

}

@end
