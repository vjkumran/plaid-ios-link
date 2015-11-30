//
//  PLDLinkBankMFASelectionsViewController.m
//  PlaidLink
//
//  Created by Simon Levy on 10/20/15.
//

#import "PLDLinkBankMFASelectionsViewController.h"

#import "PLDAuthentication.h"
#import "PLDInstitution.h"
#import "PLDLinkBankMFASelectionsView.h"
#import "PLDLinkBankMFASelectionViewController.h"

@interface PLDLinkBankMFASelectionsViewController ()<PLDLinkBankMFASelectionViewControllerDelegate>
@end

@implementation PLDLinkBankMFASelectionsViewController {
  NSMutableArray *_answers;
  NSArray *_selections;
  PLDLinkBankMFASelectionsView *_view;
  PLDInstitution *_institution;
  int _currentChildViewController;
}

- (instancetype)initWithAuthentication:(PLDAuthentication *)authentication
                           institution:(PLDInstitution *)institution {
  if (self = [super initWithAuthentication:authentication institution:institution]) {
    _institution = institution;
    _answers = [NSMutableArray array];
    _selections = authentication.mfa.data;
    _currentChildViewController = 0;
    for (PLDMFAAuthenticationSelection *selection in _selections) {
      PLDLinkBankMFASelectionViewController *selectionViewController =
          [[PLDLinkBankMFASelectionViewController alloc] initWithAuthenticationSelection:selection
                                                                             institution:institution];
      selectionViewController.delegate = self;
      [self addChildViewController:selectionViewController];
    }
  }
  return self;
}

- (void)loadView {
  _view = [[PLDLinkBankMFASelectionsView alloc] initWithFrame:CGRectZero
                                                tintColor:_institution.backgroundColor];
  self.view = _view;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  UIViewController *viewController = [self currentChildViewController];
  [_view setCurrentSelectionView:viewController.view];
  [viewController didMoveToParentViewController:self];
}

#pragma mark - PLDLinkBankMFASelectionViewControllerDelegate

- (UIViewController *)currentChildViewController {
  return [self.childViewControllers objectAtIndex:_currentChildViewController];
}

- (void)selectionViewController:(PLDLinkBankMFASelectionViewController *)viewController
                didChooseAnswer:(NSString *)answer {
  [_answers addObject:answer];
  if ([_answers count] < [_selections count]) {
    [self showNextViewController];
    return;
  }
  __weak PLDLinkBankMFASelectionsViewController *weakSelf = self;
  [self submitMFAStepResponse:_answers options:nil completion:^(NSError *error) {
    if (error) {
      UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:[error localizedDescription]
                                          message:[error localizedRecoverySuggestion]
                                   preferredStyle:UIAlertControllerStyleAlert];
      UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {}];
      
      [alert addAction:defaultAction];
      [weakSelf presentViewController:alert animated:YES completion:nil];
    }
  }];
}

- (void)showNextViewController {
  _currentChildViewController++;
  UIViewController *currentViewController = [self currentChildViewController];
  [_view setCurrentSelectionView:currentViewController.view];
  [currentViewController didMoveToParentViewController:self];
}

@end
