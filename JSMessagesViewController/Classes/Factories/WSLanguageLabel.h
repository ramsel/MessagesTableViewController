//
//  WSParser.h
//  WordsicleChat_EJ
//
//  Created by Admin on 5/12/13.
//  Copyright (c) 2013 Wordsicle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTTAttributedLabel.h"
#import <OHAttributedLabel/NSAttributedString+Attributes.h>

@protocol WSAutocompleteDataSource <NSObject>

- (NSAttributedString*)languageLabel:(WSLanguageLabel*)languageLabel
            completionForPrefix:(NSString*)prefix
                     ignoreCase:(BOOL)ignoreCase;

@end


@protocol WSLanguageLabelDelegate <NSObject>

- (void)labelTextDidChange:(id)sender;

@end

@interface WSLanguageLabel : TTTAttributedLabel {
    
}

- (id)initWithText:(NSAttributedString *)attributedText;

- (void)userIsTyping:(NSString*)typedText;


#pragma mark - Change Text
-(void)replaceText:(NSString*)text;
-(void)clearAllText;



#pragma mark - Colors & Links
-(void)colorWords:(NSDictionary*)wordsAndRanges;
-(void)colorWordsWithLinks:(NSDictionary*)wordsAndRanges;





#pragma mark - Centering
- (void)centerVerticallyInSuperview;



#pragma mark Parsing Options & Methods
@property (nonatomic, assign) BOOL parseAfterLetter;
@property (nonatomic, assign) BOOL parseAfterWord;
@property (nonatomic, assign) BOOL parseAfterMessage;

- (void)parseEntireMessage:(NSAttributedString*)text isUser:(BOOL)isUser addToWriteCount:(BOOL)addToWriteCount;


#pragma mark - Change Text
-(NSAttributedString*)getAttributedLabelText;
//-(void)setAttributedLabelTextWithOriginalAttributes:(NSAttributedString*)newText;
-(void)setAttributedLabelText:(NSAttributedString*)newText;


#pragma mark - Translation
@property (assign, nonatomic) BOOL translationsEnabled;
@property (assign, nonatomic) BOOL showsTranslation;
-(void)toggleTranslation;

// Holds original un-translated text and translated text
@property (nonatomic, strong) NSAttributedString *preTranslatedAttributedString;
@property (nonatomic, strong) NSAttributedString *translatedAttributedString;

// Fonts
@property (nonatomic, strong) UIFont* fontOriginal;
@property (nonatomic, assign) int fontSizeOriginal;
@property (nonatomic, assign) int fontSizeTranslated;





#pragma mark Flags
@property (nonatomic, assign) BOOL isWordlistWord;



#pragma mark Autocomplete
@property (nonatomic, assign) NSUInteger autocompleteType; // Can be used by the dataSource to provide different types of autocomplete behavior
@property (nonatomic, assign) BOOL autocompleteDisabled;
@property (nonatomic, assign) BOOL ignoreCase;
- (void)clearAutocompleteTextFromLabel:(NSString*)text;

// Autocomplete Datasource
@property (nonatomic, assign) id<WSAutocompleteDataSource> autocompleteDataSource;
+ (void)setDefaultAutocompleteDataSource:(id<WSAutocompleteDataSource>)dataSource;

// WSLanguageLabel Delegate
@property (nonatomic, assign) id<WSLanguageLabelDelegate> languageLabelDelegate;




@end
