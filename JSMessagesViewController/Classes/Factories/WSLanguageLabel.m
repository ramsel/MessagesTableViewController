//
//  WSParser.m
//  WordsicleChat_EJ
//
//  Created by Admin on 5/12/13.
//  Copyright (c) 2013 Wordsicle. All rights reserved.
//

#import "WSLanguageLabel.h"
#import "WSAutocompleteManager.h"

static NSObject<WSAutocompleteDataSource> *DefaultAutocompleteDataSource = nil;

@interface WSLanguageLabel ()

// Holds the current autocomplete suggestion
@property (nonatomic, strong) NSMutableAttributedString *autocompleteAttributedString;
// Text from source
@property (nonatomic, strong) NSString *typedText;
// Text from incoming message
@property (nonatomic, strong) NSString *receivedText;
// Holds all the previously parsed words
@property (nonatomic, strong) NSMutableArray *parsedWords;




@end

@implementation WSLanguageLabel {
    // Holds the last couple characters to check if they're alphanumeric
    unichar lastChar;
    unichar penultimateChar;

    // Holds the last two deleted characters
    unichar deletedChar;
    unichar previouslyDeletedChar;
        
    BOOL isWord;

  

}

@synthesize showsTranslation;

- (void)initializer {
    
    // Init variables
    self.showsTranslation = NO;
    
    // Make clickable
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(toggleTranslation)];
    tap.delegate = self;
    [self addGestureRecognizer:tap];
    
}

- (id)initWithText:(NSAttributedString *)attributedText{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.attributedText = attributedText;
        
        [self initializer];
    }
    return self;

}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializer];
    }
    return self;
}




#pragma mark - Parse Incoming Text (Deprecated)
- (void)getLastCharTyped
{
    NSLog(@"in NSBubbleData.m -- getLastCharTyped -- START");
    
    //    unichar lastChar;
    
    //    if([lastCharString length] > 0) { //.. did they type?
    //        lastChar = [self.typedText characterAtIndex:[self.typedText length]];
    //    }
    //    else
    if([self.typedText length] > 0){ //.. or delete?
        lastChar = [self.typedText characterAtIndex:[self.typedText length] - 1];
    }
    else { //.. or they've deleted all the way to the beginning
//        lastChar = NULL;
    }
}

- (void)getPenultimateCharTyped
{
    NSLog(@"in NSBubbleData.m -- getPenultimateCharTyped -- START");
    
    //    unichar penultimateChar;
    
    if ([self.typedText length] > 1) {
        penultimateChar = [self.typedText characterAtIndex:[self.typedText length] - 2];
    }
    else {
        // dummy to flag as alpha
        penultimateChar = [@"a" characterAtIndex:0];
    }
    
    //    return penultimateChar;
}

- (void)userIsTyping:(NSString*)typedText {
    // REWRITE
    // 1. CHECK IF CHARACTER ENTERED OR DELETED
    // 2. CHECK IF IT'S A LETTER OR NON-LETTER
    // 3. CHECK IF WE SHOULD PARSE OR NOT

    NSLog(@"in WSLanguageLabel -- userIsTyping -- START");

    // Get the text
    self.typedText = typedText;
    NSLog(@"self.typedText = %@", self.typedText);

    // Clear the autocomplete text from the label
    [self clearAutocompleteTextFromLabel:self.typedText];

    // First get the string and last two characters...
    [self getLastCharTyped];
    [self getPenultimateCharTyped];
    
    // Setup the character sets
    NSCharacterSet *punctuationCharacterSet = [NSCharacterSet punctuationCharacterSet];
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *alphaNumericCharacterSet = [NSCharacterSet alphanumericCharacterSet];

    NSLog(@"[self.typedText length] = %d", [self.typedText length]);
    NSLog(@"[self.label.attributedText length] = %d", [self.attributedText length]);
    
    
    
    // ...Then either add it to the message string...
    // Did they enter a character?
    if([self.typedText length] > [self.attributedText length]){
        
        // Add it to the label
        // (need to set the text color (of this char) with setTextColor because it's using OHAttributedLabel's NSAttributedString Category)
        NSMutableAttributedString* lastCharAttributed = [NSMutableAttributedString attributedStringWithString:[NSString stringWithFormat:@"%c" , lastChar]];
//        NSRange charRange = NSMakeRange(0, 1);
//        [lastCharAttributed setTextColor:[UIColor grayColor] range:charRange];

        // (now append that to the existing string and set it in the label)
        [self appendText:lastCharAttributed];


        NSLog(@"[self.typedText] = %@", self.typedText);

        
        // Is the last character a letter or non-letter?
        if ([punctuationCharacterSet characterIsMember:lastChar] ||
            [whitespaceAndNewlineCharacterSet characterIsMember:lastChar] ||
            [punctuationCharacterSet characterIsMember:penultimateChar] ||
            [whitespaceAndNewlineCharacterSet characterIsMember:penultimateChar])
        {
            
            // Check that the penultimate character was a letter...
            if (![punctuationCharacterSet characterIsMember:penultimateChar] &&
                ![whitespaceAndNewlineCharacterSet characterIsMember:penultimateChar])
            {
                
                // Parse if parseAfterWord equals YES
                if(self.parseAfterWord) {
                    [self parseLastWord:NO];
                }
                
            }
            
            // Flag for autocomplete
            isWord = NO;
        }
        
        else {
            // Flag for autocomplete
            isWord = YES;
            
            // Parse if parseAfterLetter equals YES
            if(self.parseAfterLetter) {
                [self parseAfterLetter:self.attributedText];
            }

        }


    }
    // ...Or delete the last character if the user went backwards...
    else if ([self.typedText length] < [[self getAttributedLabelText] length]) {

        // then delete the char
        [self deleteLastChar];

        // If - they've deleted a letter
        if ([alphaNumericCharacterSet characterIsMember:deletedChar]) {
            isWord = YES;
            
            // If - parseAfterLetter equals YES then parse
            if(self.parseAfterLetter) {
                [self parseAfterLetter:self.attributedText];
            }
            
            // If - they've just started deleting a word
            if ([punctuationCharacterSet characterIsMember:previouslyDeletedChar] ||
                [whitespaceAndNewlineCharacterSet characterIsMember:previouslyDeletedChar]){

                NSDictionary *removedWordAndRange = [self.parsedWords lastObject];
                [self.parsedWords removeLastObject];
                [self userIsDeletingWord:removedWordAndRange];

                //            [self parseText:NO];
            }
        }
        else {
            isWord = NO;
        }
        previouslyDeletedChar = deletedChar;
    }



    [self protocolOrNotificationThatLabelTextChanged];


    
    
    // Call Autocomplete?
    if (isWord == YES) {
        //        ! -- this is being called on the second space!
        [self refreshAutocompleteText:self.typedText];
    }
    else {
        
        [self clearAutocompleteTextFromLabel:self.typedText];
    }
    
    
    // Set this for next call
    deletedChar = lastChar;

}




- (void)userIsDeletingWord:(NSDictionary*)wordAndPosition {
    NSLog(@"in NSBubbleData -- userIsDeletingWord");
    
    int lastPosition = 0;
    int wordLength = 0;
    NSString *word = nil;
    
    for (NSString *aWord in wordAndPosition){
        word = [NSString stringWithString:aWord];
        wordLength = aWord.length;
        lastPosition = [[wordAndPosition objectForKey:aWord] intValue];
    }
    
    
    NSLog(@"in WSChatVC -- userIsDeletingWord - 2");
    NSRange stringRange = NSMakeRange(lastPosition, (self.typedText.length-lastPosition));
    NSLog(@"in WSChatVC -- userIsDeletingWord - 3");
    //    stringRange = [nonAttributedString rangeOfComposedCharacterSequencesForRange:stringRange];
    
    NSLog(@"in WSChatVC -- userIsDeletingWord - 4");
    
    NSLog(@"[sayBubble.label.attributedText length] =  %lu", (unsigned long)[self.attributedText length]);
    NSLog(@"range.location =  %lu", (unsigned long)stringRange.location);
    NSLog(@"range.length =  %lu", (unsigned long)stringRange.length);
    
    // set color and remove the links
//    [self removeLinkFromWord:word withColor:[UIColor colorMessageNonWord] atRange:stringRange];
    
    NSLog(@"in WSChatVC -- userIsDeletingWord - 5");
    
    // decrement the count
    [[WSUserManager shared] subtractFromCount:word count:[NSNumber numberWithInt:1]];
    
    NSLog(@"in WSChatVC -- userIsDeletingWord - 6");
    
    
}

- (BOOL)isPuncOrWhitespace {
    // TODO -- IMPLEMENT THIS FOR AUTOCOMLETE -- MOVE PUNC AND WHITESPACE CHECKS HERE FROM USERISTYPING
    return YES;
}

- (void)parseLastWord:(BOOL)didDelete {
    NSLog(@"in NSBubbleData.m -- parseText -- START");
    
    
    
    // Retrieve the range of the last word entered (need to convert from value to struct)
    int lastPosition = 0;
    int wordLength = 0;
    NSRange stringRange = {0,0};
    NSDictionary *lastWordAndPosition = nil;
    
    if([self.parsedWords count] > 0) {
        // Get last word...
        if (didDelete == NO) {
            lastWordAndPosition = [self.parsedWords lastObject];
        }
        // ... or last last word if they deleted
        else {
            NSLog(@"didDelete == YES");
            lastWordAndPosition = [self.parsedWords objectAtIndex:[self.parsedWords count]-2];
        }
        
        // ... then get that word's positions
        for (NSString *word in lastWordAndPosition){
            NSLog(@"word = %@", word);
            
            wordLength = word.length;
            lastPosition = [[lastWordAndPosition objectForKey:word] intValue]+wordLength;
        }
    }
    
    
    stringRange = NSMakeRange(lastPosition, (self.typedText.length-lastPosition));
    NSLog(@"stringRange.location = %lu", (unsigned long)stringRange.location);
    NSLog(@"stringRange.location = %lu", (unsigned long)stringRange.location);
    NSLog(@"stringRange.length = %lu", (unsigned long)stringRange.length);
    stringRange = [self.typedText rangeOfComposedCharacterSequencesForRange:stringRange];
    
    NSLog(@"[nonAttributedString length] = %lu", (unsigned long)[self.typedText length]);
    NSLog(@"stringRange.location = %lu", (unsigned long)stringRange.location);
    NSLog(@"stringRange.length = %lu", (unsigned long)stringRange.length);
    NSLog(@"lastPosition = %lu", (unsigned long)lastPosition);
    NSLog(@"wordLength = %lu", (unsigned long)wordLength);
    
    if (didDelete == YES) {
        
        // TODO -- IMPLEMENT THE CASE WHERE THEY DELETE A WORD!! -- I THINK ALL THAT'S NEEDED IS TO SUBTRACT THIS FROM THEIR WORDLIST
        // TODO -- ALSO, IF THEY DELETE A WORD PARTIALLY THAT'S BEEN HIGHLIGHTED, IT REMAINS HIGHLIGHTED!! -- UNHILIGHT!
    }
    
    
    // Use NSLinguisticTagger to parse the text
    NSArray *language = [NSArray arrayWithObjects:@"en",@"de",@"fr",nil];
    NSDictionary* languageMap = [NSDictionary dictionaryWithObject:language forKey:@"Latn"];
    
    NSString *substring = [self.typedText substringWithRange:stringRange];
    NSRange substringRange = NSMakeRange(0, substring.length);
    
    
    [substring enumerateLinguisticTagsInRange:substringRange
                                       scheme:NSLinguisticTagSchemeTokenType
                                      options:NSLinguisticTaggerOmitWhitespace | NSLinguisticTaggerOmitPunctuation | NSLinguisticTaggerJoinNames
                                  orthography:[NSOrthography orthographyWithDominantScript:@"Latn" languageMap:languageMap]
                                   usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
                                       
                                       NSLog(@"*** TAG *** %@ is a %@",[substring substringWithRange:tokenRange] ,tag);
                                       
                                       // Now if the token is a word...
                                       if ([tag isEqualToString:@"Word"])
                                       {
                                           // ..Then let's see if it's a word in the wordlist dictionary
                                           NSString *lowerCaseStringEntered = [[substring substringWithRange:tokenRange] lowercaseString];
                                           if([[WSWordlistManager shared] hasWord:lowerCaseStringEntered]) {
                                               
//                                               // add to the count and then retrieve it
//                                               [[WSUserManager shared] addToCount:lowerCaseStringEntered count:[NSNumber numberWithInt:1]];
//                                               int count = [[WSUserManager shared] getCountForWord:lowerCaseStringEntered];
                                               
                                               
//                                               // set color and create the link
//                                               UIColor *color = [[WSWordlistManager shared] getColorFromScheme:count];
//                                               [self colorWordUsingLinks:lowerCaseStringEntered withColor:color atRange:stringRange forCount:count];
                                               
                                               
                                               // Tell controller to do something (reload table)
                                               [self protocolOrNotificationThatLabelTextChanged];
//                                               [self.delegate chatDataDidChangeMessage:self];
                                           }
                                           
                                           // (And add to the tracking dictionary)
                                           NSMutableDictionary *wordAndRange = [[NSMutableDictionary alloc] init];
                                           [wordAndRange setObject:[NSNumber numberWithInt:(stringRange.location + tokenRange.location)] forKey:lowerCaseStringEntered];
                                           
                                           [self.parsedWords addObject:wordAndRange];
                                           NSLog(@"*******************");
                                           NSLog(@"wordAndRange = %@", wordAndRange);
                                       }
                                   }];
    
    
}

- (void)parseAfterLetter:(NSAttributedString*)attributedString{
    NSLog(@"in NSBubbleData.m -- parseText -- START");

    
    // Use NSLinguisticTagger to parse the text
    NSArray *language = [NSArray arrayWithObjects:@"en",@"de",@"fr",nil];
    NSDictionary* languageMap = [NSDictionary dictionaryWithObject:language forKey:@"Latn"];
    
//    NSString *substring = [self.typedText substringWithRange:stringRange];
//    NSRange range = NSMakeRange(0, self.attributedText.length);
    
    NSString *string = [attributedString string];
    NSRange range = NSMakeRange(0, string.length);

    [string enumerateLinguisticTagsInRange:range
                                    scheme:NSLinguisticTagSchemeTokenType
                                      options:NSLinguisticTaggerOmitWhitespace | NSLinguisticTaggerOmitPunctuation | NSLinguisticTaggerJoinNames
                                  orthography:[NSOrthography orthographyWithDominantScript:@"Latn" languageMap:languageMap]
                                   usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
                                       
                                       NSLog(@"*** TAG *** %@ is a %@",[string substringWithRange:tokenRange] ,tag);
                                       
                                       // Check if token is a word
                                       if ([tag isEqualToString:@"Word"])
                                       {
                                           // ..Then let's see if it's a word in the wordlist dictionary
                                           NSString *lowerCaseStringEntered = [[self.text substringWithRange:tokenRange] lowercaseString];
                                           if([[WSWordlistManager shared] hasWord:lowerCaseStringEntered]) {
                                               
                                               // Color it
//                                               [self colorLabelText:[UIColor colorChatTableHeaderTitle]];
                                               self.isWordlistWord = YES;
                                               
                                           }
                                           else {
//                                               [self colorLabelText:[UIColor lightGrayColor]];
                                               self.isWordlistWord = NO;

                                           }
                                           

                                       }
                                   }];
    
    

    
}


- (void)parseEntireMessage:(NSAttributedString*)text isUser:(BOOL)isUser addToWriteCount:(BOOL)addToWriteCount
{
    NSLog(@"in SMChatViewController -- parseReceivedText");
    
    //    NSAttributedString *text = [[NSAttributedString alloc] initWithString:message];
    
    
    // Use NSLinguisticTagger to parse the text
    NSArray *language = [NSArray arrayWithObjects:@"en",@"de",@"fr",nil];
    NSDictionary* languageMap = [NSDictionary dictionaryWithObject:language forKey:@"Latn"];
    NSString *string = [text string];
    NSRange range = NSMakeRange(0, string.length);
    
    
    [string enumerateLinguisticTagsInRange:range
                                    scheme:NSLinguisticTagSchemeTokenType
                                   options:NSLinguisticTaggerOmitWhitespace | NSLinguisticTaggerOmitPunctuation | NSLinguisticTaggerJoinNames
                               orthography:[NSOrthography orthographyWithDominantScript:@"Latn" languageMap:languageMap]
                                usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
                                    
                                    NSLog(@"*** TAG *** %@ is a %@",[string substringWithRange:tokenRange] ,tag);
                                    
                                    // Now if the token is a word...
                                    if ([tag isEqualToString:@"Word"])
                                    {
                                        // ..Then let's see if it's a word in the wordlist dictionary
                                        NSString *lowerCaseStringEntered = [[string substringWithRange:tokenRange] lowercaseString];
                                        if([[WSWordlistManager shared] hasWord:lowerCaseStringEntered]) {
                                            
                                            // add to the count if user
                                            if(isUser){
                                                [[WSUserManager shared] addToCount:lowerCaseStringEntered count:[NSNumber numberWithInt:1]];
                                            }
                                            
                                            // retrieve the count
                                            int count = [[WSUserManager shared] getCountForWord:lowerCaseStringEntered];
                                            
                                            // set color and create the link
                                            UIColor *color = [[WSWordlistManager shared] getColorFromScheme:count];
                                            NSLog(@"WSLanguageLabel -- parseEntireMessage -- color = %@", color);

//                                            [self colorWordUsingLinks:lowerCaseStringEntered withColor:color atRange:tokenRange forCount:count];
                                            
                                            
                                            
                                            // add it to their words if they don't own it yet
                                            if (isUser && addToWriteCount) {
                                                
                                                if (![[WSUserManager shared] hasWord:lowerCaseStringEntered]) {
                                                    [[WSUserManager shared] addNewWord:lowerCaseStringEntered];
                                                
                                                }
                                            }
                                            
                                            [self.languageLabelDelegate labelTextDidChange:self];
                                        }
                                    }
                                }];
    
//    NSLog(@"receivedBubble.label.attributedText = %@", [self.label.attributedText string]);
    
//    [self adjustLabelSize];
    
    
}


- (NSMutableAttributedString*)parseMessageForTranslation:(NSAttributedString*)text{
    NSLog(@"in SMChatViewController -- parseReceivedText");
    
    NSMutableAttributedString *translatedText = [[NSMutableAttributedString alloc] initWithString:@""];

    
    // Use NSLinguisticTagger to parse the text
    NSArray *language = [NSArray arrayWithObjects:@"en",@"de",@"fr",nil];
    NSDictionary* languageMap = [NSDictionary dictionaryWithObject:language forKey:@"Latn"];
    NSString *string = [text string];
    NSRange range = NSMakeRange(0, string.length);
    
    
    [string enumerateLinguisticTagsInRange:range
                                    scheme:NSLinguisticTagSchemeTokenType
                                   options:NSLinguisticTaggerJoinNames
                               orthography:[NSOrthography orthographyWithDominantScript:@"Latn" languageMap:languageMap]
                                usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
                                    
                                    NSLog(@"*** TAG *** %@ is a %@",[string substringWithRange:tokenRange] ,tag);
                                    
                                    // Set the tokens
                                    NSString *token = [string substringWithRange:tokenRange];
                                    NSMutableAttributedString *attributedToken = [NSMutableAttributedString attributedStringWithString:token];
                                    
                                    NSLog(@"token = %@",token);

                                    // Set the default color
                                    [attributedToken setTextColor:[UIColor colorMessageNonWord]];
                                    
                                    // Now if the token is a word...
                                    if ([tag isEqualToString:@"Word"])
                                    {
                                        // ..Then let's see if it's a word in the wordlist dictionary
                                        NSString *lowercaseToken = [token lowercaseString];
                                        if([[WSWordlistManager shared] hasWord:lowercaseToken]) {
                                            
                                            // retrieve translation
                                            NSString* translatedToken = [[WSWordlistManager shared] getNativeWord:lowercaseToken];
                                            NSMutableAttributedString* attributedTranslatedToken = [NSMutableAttributedString attributedStringWithString:translatedToken];
                                            
                                            // retrieve the count
                                            int count = [[WSUserManager shared] getCountForWord:lowercaseToken];
                                            
                                            // set color
                                            UIColor *color = [[WSWordlistManager shared] getColorFromScheme:count];
                                            [attributedTranslatedToken setTextColor:color];                                            
                                            [attributedTranslatedToken setFont:[UIFont boldSystemFontOfSize:self.fontSizeOriginal]];
                                        

                                            
                                            // copy it back to the main string
                                            attributedToken = [attributedTranslatedToken copy];
                                        }
                                                                        
                                    }
                                    
                                    
                                    // Add whatever token to the translated text
                                    [translatedText appendAttributedString:attributedToken];
                                }];
    

    
    return translatedText;
}



#pragma mark - Resize
//- (void)adjustLabelSize {
//    NSMutableAttributedString* text = [self.attributedText mutableCopy];
//    
//    // Set font and frame
//    UIFont *font = [UIFont boldSystemFontOfSize:kConversationMessageFontSize];
//    [text setFontFamily:kConversationMessageFontName size:kConversationMessageFontSize bold:NO italic:NO range:NSMakeRange(0,[text length])];
//    NSString *nonAttributedText = [text string];
//    CGSize size = [nonAttributedText sizeWithFont:font constrainedToSize:CGSizeMake(kConversationMaxBubbleWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
//    self.frame = CGRectMake(0.0, 0.0, size.width, size.height);
//    
//    [self.languageLabelDelegate labelTextDidChange:self];
//}

#pragma mark - Centering
- (void)centerVerticallyInSuperview {
    float yPos = (CGRectGetHeight(self.superview.frame) - CGRectGetHeight(self.frame)) / 2;
    self.frame = CGRectMake(self.frame.origin.x, yPos, self.frame.size.width, self.frame.size.height);
}

#pragma mark - Change Text
-(void)replaceText:(NSString*)text {
    NSMutableAttributedString* newLabelText = [NSAttributedString attributedStringWithString:text];
    
    [self setText:newLabelText afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        return mutableAttributedString;
    }];
    
    [self sizeToFit];
}

-(void)clearAllText {
    NSMutableAttributedString* newLabelText = [NSAttributedString attributedStringWithString:@""];

    [self setText:newLabelText afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        return mutableAttributedString;
    }];
    
    [self sizeToFit];

}

-(void)appendText:(NSMutableAttributedString*)mutableAttributedText
{
    NSLog(@"in WSLanguageLabel -- appendText -- START");
    
    
    NSMutableAttributedString* newLabelText = [[self getAttributedLabelText] mutableCopy];
    [newLabelText appendAttributedString:mutableAttributedText];
    
    [self setText:newLabelText afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        return mutableAttributedString;
    }];

    NSLog(@" self.attributedText = %@", self.attributedText);
    
    
    
    [self sizeToFit];
}

-(void)deleteLastChar {

    NSMutableAttributedString* newLabelText = [[self getAttributedLabelText] mutableCopy];
    [newLabelText deleteCharactersInRange:NSMakeRange([newLabelText length]-1, 1)];
    
    [self setText:newLabelText afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        return mutableAttributedString;
    }];
    
    
    [self sizeToFit];

}

//
//-(void)setAttributedLabelTextWithOriginalAttributes:(NSAttributedString*)newText{
//    
////    self.font = [self.fontOriginal fontWithSize:self.fontSizeOriginal];
//
//    [self setText:newText];
//}

-(void)setAttributedLabelText:(NSAttributedString*)newText{
    [self setText:newText];
}

-(NSAttributedString*)getAttributedLabelText{
    return self.attributedText;
}

#pragma mark - Colors & Links

-(void)colorWords:(NSDictionary*)wordsAndRanges {
    
    [self colorLabelTextWithBaseColor];

    
    __block NSMutableAttributedString* mutableAttributedString = [NSMutableAttributedString attributedStringWithAttributedString:self.attributedText];

    [wordsAndRanges enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        NSString* word = (NSString*)key;
        NSRange range = [obj rangeValue];
        
        
        if ([word isKindOfClass:[NSString class]]) {
            // retrieve the count
            int count = [[WSUserManager shared] getCountForWord:key];
            
            // set color
            UIColor *color = [[WSWordlistManager shared] getColorFromScheme:count];
            [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[color CGColor] range:range];
        }
        

    }];
    
    [self setText:mutableAttributedString];
    
}

-(void)colorWordsWithLinks:(NSDictionary*)wordsAndRanges{
    
    // Reset the base color (for some reason it's getting reset)
    [self colorLabelTextWithBaseColor];
    
    
    // Enumerate the words and ranges
    [wordsAndRanges enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        NSString* word = (NSString*)key;
        NSRange range = [obj rangeValue];
        
        
        if ([word isKindOfClass:[NSString class]]) {
            // retrieve the count
            int count = [[WSUserManager shared] getCountForWord:key];
            
            // set color
            UIColor *color = [[WSWordlistManager shared] getColorFromScheme:count];
            
            [self createLinkFromWord:word withColor:color atRange:range];
            
        }
        
        
    }];
    
}

-(void)colorLabelTextWithBaseColor {
    
    NSMutableAttributedString* mutableAttributedString = [NSMutableAttributedString attributedStringWithAttributedString:self.attributedText];
    
    // set color
    UIColor *color = [[WSWordlistManager shared] getColorFromScheme:0];
    NSRange range = NSRangeFromString([mutableAttributedString string]);
    [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[color CGColor] range:range];
    
    
    [self setText:mutableAttributedString afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        
        [mutableAttributedString addAttribute:(id)kCTForegroundColorAttributeName value:color range:range];
        
        return mutableAttributedString;
    }];

}



//-(void)colorLabelText:(UIColor*)color {
//    NSRange range = NSMakeRange(0,[self.text length]);
//
//    [self setText:self.text afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
//        [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[color CGColor] range:range];
//        return mutableAttributedString;
//    }];
//
//}

//-(void)colorWordUsingLinks:(NSString*)word withColor:(UIColor*)color atRange:(NSRange)range forCount:(int)count {
//    NSLog(@"in WSLanguageLabel -- colorWordUsingLinks");
//    
//    NSLog(@"color = %@", color);
//    NSLog(@"word = %@", word);
//    NSLog(@"count = %d", count);
//
//
//    
//    BOOL isBold = NO;
//    NSURL *url = nil;
//    
//    // If passsed a word, create a translation link for it
//    if(word){
//        NSString *translatedWord = [[WSWordlistManager shared] getNativeWord:word];
//        NSString *stringForURL = [@"action://" stringByAppendingString:translatedWord];
//        url = [NSURL URLWithString:stringForURL];
//    }
//    
//    UIColor *theColor;
//    
//    // If user now owns the word, then blink it
//    if (count == kCountOwned) {
//        isBold = YES;
//        
//        // Keep the original color until it blinks
//        theColor = (id)[[[WSWordlistManager shared] getColorFromScheme:(count-1)] CGColor];
//        
//        // Now blink to white and then 'color owned'
//        [self performSelector:@selector(blinkColorWhiteAtRange:) withObject:[NSValue valueWithRange:range] afterDelay:0.5 ];
//        [self performSelector:@selector(blinkColorOwnedAtRange:) withObject:[NSValue valueWithRange:range] afterDelay:0.8 ];
//    }
//    else {
//        theColor = (id)[color CGColor];
//    }
//    
//    // Set the link (and color)
//    NSArray *keys = [[NSArray alloc] initWithObjects:(id)kCTForegroundColorAttributeName,(id)kCTUnderlineStyleAttributeName, nil];
//    NSArray *objects = [[NSArray alloc] initWithObjects:theColor,[NSNumber numberWithInt:kCTUnderlineStyleNone], nil];
//    
//    NSLog(@"object array = %@", objects);
//    NSLog(@"theColor = %@", theColor);
//    NSLog(@"[NSNumber numberWithInt:kCTUnderlineStyleNone] = %@", [NSNumber numberWithInt:kCTUnderlineStyleNone]);
//
//
//    
//    NSDictionary *linkAttributes = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
//    self.linkAttributes = linkAttributes;
//    
//    [self addLinkToURL:url withRange:range];
//    
//    //    // Bold the word if it's just now owned
//    //    if (isBold) {
//    //        [self.label setText:self.label.attributedText afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
//    //
//    //                // Core Text APIs use C functions without a direct bridge to UIFont. See Apple's "Core Text Programming Guide" to learn how to configure string attributes.
//    //                UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:kMessageFontSize];
//    //                CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
//    //                if (font) {
//    //                    [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:range];
//    //                    CFRelease(font);
//    //                }
//    //
//    //                [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)(font) range:range];
//    //
//    //            return mutableAttributedString;
//    //        }];
//    //    }
//    
//    
//    
//    
//    
//    //    NSLog(@">>>>>>>> self.label.links =  %@", self.label.links);
//    
//}

//-(void)removeLinkFromWord:(NSString*)word withColor:(UIColor*)color atRange:(NSRange)range {
//    NSLog(@"in NSBubbleData.m -- removeLinkFromWord -- START");
//    
//    // Since working with links is so confusing, instead of removing this link I'm just going to set it to a blank string
//    NSString *stringForURL = [@"action://" stringByAppendingString:@""];
//    NSURL *url = [NSURL URLWithString:stringForURL];
//    
//    
//    UIColor *theColor = (id)[color CGColor];
//    NSArray *keys = [[NSArray alloc] initWithObjects:(id)kCTForegroundColorAttributeName,(id)kCTUnderlineStyleAttributeName, nil];
//    NSArray *objects = [[NSArray alloc] initWithObjects:theColor,[NSNumber numberWithInt:kCTUnderlineStyleNone], nil];
//    NSDictionary *linkAttributes = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
//    self.linkAttributes = linkAttributes;
//    
//    
//    
//    [self addLinkToURL:url withRange:range];
//    
//    //    NSLog(@">>>>>>>> self.label.links =  %@", self.label.links);
//    NSLog(@"in NSBubbleData.m -- removeLinkFromWord -- END");
//    
//    
//}






- (void)createLinkFromWord:(NSString*)word withColor:(UIColor*)color atRange:(NSRange)range{
//    NSMutableAttributedString* newTextWithLinks = [self.attributedText mutableCopy];
    
    NSString* urlString = [[@"word" stringByAppendingString:@"://"] stringByAppendingString:word];
    NSURL *url = [NSURL URLWithString:urlString];
    
    
    NSArray *keys = [[NSArray alloc] initWithObjects:(id)kCTForegroundColorAttributeName,(id)kCTUnderlineStyleAttributeName
                     , nil];
    NSArray *objects = [[NSArray alloc] initWithObjects:color,[NSNumber numberWithInt:kCTUnderlineStyleNone], nil];
    NSDictionary *linkAttributes = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
    
    self.linkAttributes = linkAttributes;
    
    [self addLinkToURL:url withRange:range];
}



#pragma mark - Autocomplete
+ (void)setDefaultAutocompleteDataSource:(id)dataSource
{
    DefaultAutocompleteDataSource = dataSource;
}


- (void)clearAutocompleteTextFromLabel:(NSString*)text
{
    NSLog(@"in NSBubbleData.m -- clearAutocompleteTextFromLabel -- START");
    
    
    if ([self.autocompleteAttributedString length] > 0){
        NSRange range = NSMakeRange(0, [text length]-1);
        
        NSLog(@"text = %@", text);
        
        
        
        // Have to remove the old autocomplete string
        int deleteLocation = range.length; // LOCATION IS RIGHT
        int deleteLength = [self.text length] - range.length; // LENGTH IS FUCKED UP
        NSLog(@"self.label.text = %@", self.text);
        NSLog(@"self.label.attr = %@", [self.attributedText string]);
        NSLog(@"range.length = %d", range.length);
        
        NSLog(@"deleteLocation = %d", deleteLocation);
        NSLog(@"deleteLength = %d", deleteLength);
        
        NSRange deleteRange = NSMakeRange(deleteLocation,deleteLength);
        NSMutableAttributedString *mutableString = [self.attributedText mutableCopy];
        NSLog(@"mutableString = %@", [mutableString string]);
        
        [mutableString deleteCharactersInRange:deleteRange];
        
        
        NSLog(@"mutableString (after deletion) = %@", [mutableString string]);
        
        self.attributedText = mutableString;
    }
    
    self.autocompleteAttributedString = [NSMutableAttributedString attributedStringWithString:@""];
    
}

- (void)updateLabelWithAutocompleteText
{
    NSLog(@"in NSBubbleData.m -- updateLabelWithAutocompleteText -- START");
    
    [self.autocompleteAttributedString setTextColor:[UIColor colorMessageAutocompleteWord] range:NSMakeRange(0, ([self.autocompleteAttributedString length]))];
    
    //    // Have to remove the old autocomplete string
    //    int deleteLocation = range.length - 1; // LOCATION IS RIGHT
    //    int deleteLength = [self.label.text length] - range.length; // LENGTH IS FUCKED UP
    //    NSLog(@"self.label.text = %@", self.label.text);
    //    NSLog(@"self.label.attr = %@", [self.label.attributedText string]);
    //
    //    NSLog(@"deleteLocation = %d", deleteLocation);
    //    NSLog(@"deleteLength = %d", deleteLength);
    //
    //    NSRange deleteRange = NSMakeRange(deleteLocation,deleteLength);
    //    NSMutableAttributedString *mutableString = [self.label.attributedText mutableCopy];
    //    NSLog(@"mutableString = %@", [mutableString string]);
    //
    //    [mutableString deleteCharactersInRange:deleteRange];
    //
    //
    //    NSLog(@"mutableString (after deletion) = %@", [mutableString string]);
    //
    //    self.label.attributedText = mutableString;
    
    //    [self.label setText:mutableString];
    
    // Then append the new autocomplete string
    [self appendText:self.autocompleteAttributedString];
    
    [self protocolOrNotificationThatLabelTextChanged];
    
}

//- (void)updateAutocompleteLabel
//{
//    NSLog(@"in NSBubbleData.m -- updateAutocompleteLabel -- START");
//
//    self.autocompleteLabel.hidden = NO;
//
//
//      // Set text and color
////    NSMutableAttributedString *mutableAutocompleteString = [[NSMutableAttributedString alloc] initWithAttributedString:self.autocompleteAttributedString];
////    [mutableAutocompleteString setTextColor:[UIColor colorMessageAutocompleteWord] range:NSMakeRange(0, ([mutableAutocompleteString length]))];
//
//    // Set label's font, color and text
////    NSMutableAttributedString* text;
////    text = [self.autocompleteLabel.attributedText mutableCopy];
//    UIFont *font = [UIFont systemFontOfSize:kMessageFontSize];
//    [self.autocompleteAttributedString setFontFamily:kMessageFontName size:kMessageFontSize bold:NO italic:NO range:NSMakeRange(0,[self.autocompleteAttributedString length])];
//    [self.autocompleteAttributedString setTextColor:[UIColor colorMessageAutocompleteWord] range:NSMakeRange(0, ([self.autocompleteAttributedString length]))];
//    [self.autocompleteLabel setText:self.autocompleteAttributedString];
//
//    // Set frame
//    NSString *nonAttributedText = [self.autocompleteAttributedString string];
//    CGSize size = [nonAttributedText sizeWithFont:font constrainedToSize:CGSizeMake(220, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
//
//
//    self.autocompleteLabel.frame = CGRectMake(self.label.frame.origin.x + self.label.frame.size.width, self.label.frame.origin.y, size.width, size.height);
//
//    // Use category method to auto-resize superview
//    [self.view resizeToFitSubviews];
//}

- (void)refreshAutocompleteText:(NSString*)text
{
    NSLog(@"in NSBubbleData.m -- refreshAutocompleteText -- START");
    
    
    if (!self.autocompleteDisabled)
    {
        id <WSAutocompleteDataSource> dataSource = nil;
        
        if ([self.autocompleteDataSource respondsToSelector:@selector(bubbleData:completionForPrefix:ignoreCase:)])
        {
            dataSource = (id <WSAutocompleteDataSource>)self.autocompleteDataSource;
        }
        else if ([DefaultAutocompleteDataSource respondsToSelector:@selector(bubbleData:completionForPrefix:ignoreCase:)])
        {
            dataSource = DefaultAutocompleteDataSource;
        }
        
        if (dataSource)
        {
            // Get last alphanumeric text entered
            __block NSString *lastWord = nil;
            [text enumerateSubstringsInRange:NSMakeRange(0, [text length]) options:NSStringEnumerationByWords | NSStringEnumerationReverse usingBlock:^(NSString *substring, NSRange subrange, NSRange enclosingRange, BOOL *stop) {
                lastWord = substring;
                *stop = YES;
            }];
            
            //            NSRange range = NSMakeRange([lastWord length]-[self.autocompleteAttributedString length], [self.autocompleteAttributedString length]);
            //            lastWord = [lastWord stringByReplacingCharactersInRange:range withString:@""];
            //
            NSLog(@"text = %@", text);
            NSLog(@"lastWord = %@", lastWord);
            
            
            self.autocompleteAttributedString = [[dataSource languageLabel:self completionForPrefix:lastWord ignoreCase:self.ignoreCase] mutableCopy];
            NSLog(@"autocompleteAttributedString = %@", self.autocompleteAttributedString);
            
            
            //            NSRange range = NSMakeRange(0, [text length]);
            if([self.autocompleteAttributedString length] > 0){
                [self updateLabelWithAutocompleteText];
            }
        }
    }
}




- (void)commitAutocompleteText
{
    NSLog(@"in NSBubbleData.m -- commitAutocompleteText -- START");
    
    
    NSString *autocompleteString = [self.autocompleteAttributedString string];
    if ([autocompleteString isEqualToString:@""] == NO
        && self.autocompleteDisabled == NO)
    {
        // NEED TO UPDATE THAT FIRST LINE TO WORK WITH MY LABELS
        //        self.label.text = [NSString stringWithFormat:@"%@%@", self.label.text, self.autocompleteAttributedString];
        //
        //        self.autocompleteAttributedString = [NSAttributedString attributedStringWithString:@""];
        //        [self updateAutocompleteLabel];
    }
}


#pragma mark - Translation
-(void)toggleTranslation
{
    
    
    if (!self.showsTranslation) {
        if (!self.translatedAttributedString) {
            self.translatedAttributedString = [self parseMessageForTranslation:[self getAttributedLabelText]];
            
            // Save original text
            self.preTranslatedAttributedString = [self getAttributedLabelText];
            self.fontSizeOriginal = self.font.pointSize;
            self.fontOriginal = self.font;
        }
        
        
        
        [self setAttributedLabelText:self.translatedAttributedString];
        
        self.showsTranslation = YES;
    }
    else {
        [self setAttributedLabelText:self.preTranslatedAttributedString];
        
        self.showsTranslation = NO;
    }
    
    
}

-(NSArray*)splitMessageIntoSentences
{    
    
    // Use NSLinguisticTagger to parse the text
    // THIS CONVERTS ALL WORD TO UPPERCASE TO ACCOUNT FOR UNCAPITALIZED SENTENCES
    NSString* text = [self.attributedText string];
    NSString* textUppercase = [text capitalizedString];
    NSLog(@"text = %@",text);
    
    
    //    NSString* string = [self.label.attributedText string];
    NSMutableArray* sentences = [[NSMutableArray alloc] init];
    
    NSArray *language = [NSArray arrayWithObjects:@"en",@"de",@"fr",nil];
    NSDictionary* languageMap = [NSDictionary dictionaryWithObject:language forKey:@"Latn"];
    NSRange range = NSMakeRange(0, textUppercase.length);
    
    
    [textUppercase enumerateLinguisticTagsInRange:range
                                           scheme:NSLinguisticTagSchemeLexicalClass
                                          options:NSLinguisticTaggerOmitWords | NSLinguisticTaggerOmitWhitespace
                                      orthography:[NSOrthography orthographyWithDominantScript:@"Latn" languageMap:languageMap]
                                       usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
                                           
                                           if ([tag isEqualToString:@"SentenceTerminator"]){
                                               NSLog(@"%@ is a %@, tokenRange (%d,%d), sentenceRange (%d,%d)",[textUppercase substringWithRange:tokenRange] ,tag,tokenRange.length,tokenRange.location, sentenceRange.length, sentenceRange.location);
                                               NSString *sentence = [textUppercase substringWithRange:sentenceRange];
                                               NSAttributedString *attributedSentence = [self.attributedText attributedSubstringFromRange:sentenceRange];
                                               [sentences addObject:attributedSentence];
                                               NSLog(@"Sentence = %@", sentence);
                                               //                                        NSLog(@"Attributed Sentence = %@", attributedSentence);
                                               
                                           }
                                           
                                       }];
    
    return sentences;
    
    
}



#pragma mark - TO IMPLEMENT
-(void)protocolOrNotificationThatLabelTextChanged{
    
}


@end
