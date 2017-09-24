/*
* Copyright 2016 Google Inc. All Rights Reserved.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

// MARK: - ToolboxCategoryListViewControllerDelegate (Protocol)

/**
 Handler for events that occur on `ToolboxCategoryListViewController`.
 */
@objc(BKYToolboxCategoryListViewControllerDelegate)
public protocol ToolboxCategoryListViewControllerDelegate: class {
  /**
  Event that occurs when a category has been selected.
  */
  func toolboxCategoryListViewController(
    _ controller: ToolboxCategoryListViewController, didSelectCategory category: Toolbox.Category)

  /**
  Event that occurs when the category selection has been deselected.
  */
  func toolboxCategoryListViewControllerDidDeselectCategory(
    _ controller: ToolboxCategoryListViewController)
}

// MARK: - ToolboxCategoryListViewController (Class)

/**
 A view for displaying a vertical list of categories from a `Toolbox`.
 */
@objc(BKYToolboxCategoryListViewController)
public final class ToolboxCategoryListViewController: UICollectionViewController {

  // MARK: - Constants
  
  static fileprivate let ToolboxWidth: CGFloat = 100

  /// Possible view orientations for the toolbox category list
  @objc(BKYToolboxCategoryListViewControllerOrientation)
  public enum Orientation: Int {
    case
      /// Specifies the toolbox is horizontally-oriented.
      horizontal = 0,
      /// Specifies the toolbox is vertically-oriented.
      vertical
  }

  // MARK: - Properties

  /// The orientation of how the categories should be laid out
  public let orientation: Orientation

  /// The toolbox layout to display
  public var toolboxLayout: ToolboxLayout?

  /// The category that the user has currently selected
  public var selectedCategory: Toolbox.Category? {
    didSet {
      if selectedCategory == oldValue {
        return
      }

      // Update the UI to match the new selected category.

      if selectedCategory != nil,
        let indexPath = indexPath(forCategory: selectedCategory),
        let cell = self.collectionView?.cellForItem(at: indexPath) , !cell.isSelected
      {
        // Select the new value (which automatically deselects the previous value)
        self.collectionView?.selectItem(
          at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
      } else if selectedCategory == nil,
        let indexPath = indexPath(forCategory: oldValue)
      {
        // No new category was selected. Just de-select the previous value.
        self.collectionView?.deselectItem(at: indexPath, animated: true)
      }
    }
  }

  /// The font to use for the category cell.
  public var categoryFont = UIFont.systemFont(ofSize: 16)

  /// The text color to use for a selected category.
  public var selectedCategoryTextColor: UIColor?

  /// The background color to use for an unselected category.
  public var unselectedCategoryBackgroundColor: UIColor?

  /// The text color to use for an unselected category.
  public var unselectedCategoryTextColor: UIColor?

  /// Delegate for handling category selection events
  public weak var delegate: ToolboxCategoryListViewControllerDelegate?

  // MARK: - Initializers

  /**
   Initializes the toolbox category list view controller.

   - parameter orientation: The `Orientation` for the view.
   */
  public required init(orientation: Orientation) {
    self.orientation = orientation

    let flowLayout = UICollectionViewFlowLayout()
    switch orientation {
    case .horizontal:
      flowLayout.scrollDirection = .horizontal
    case .vertical:
      flowLayout.scrollDirection = .vertical
    }

    super.init(collectionViewLayout: flowLayout)
  }

  /**
   :nodoc:
   - Warning: This is currently unsupported.
   */
  public required init?(coder aDecoder: NSCoder) {
    fatalError("Called unsupported initializer")
  }

  // MARK: - Super

  open override func viewDidLoad() {
    super.viewDidLoad()

    guard let collectionView = self.collectionView else {
      bky_print("`self.collectionView` is nil. Did you forget to set it?")
      return
    }

    collectionView.backgroundColor = .clear
    collectionView.register(ToolboxCategoryListViewCell.self,
      forCellWithReuseIdentifier: ToolboxCategoryListViewCell.ReusableCellIdentifier)
    collectionView.showsVerticalScrollIndicator = false
    collectionView.showsHorizontalScrollIndicator = false

    // Automatically constrain this view to a certain size
    if orientation == .horizontal {
        view.bky_addHeightConstraint(ToolboxCategoryListViewController.ToolboxWidth)
    } else {
        view.bky_addWidthConstraint(ToolboxCategoryListViewController.ToolboxWidth)
    }
  }

  // MARK: - Public

  /**
   Refreshes the UI based on the current version of `self.toolbox`.
   */
  public func refreshView() {
    self.collectionView?.reloadData()
  }

  // MARK: - UICollectionViewDataSource overrides

  public override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  public override func collectionView(
    _ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return toolboxLayout?.categoryLayoutCoordinators.count ?? 0
  }

  public override func collectionView(_ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: ToolboxCategoryListViewCell.ReusableCellIdentifier,
      for: indexPath) as! ToolboxCategoryListViewCell
    cell.nameLabel.font = categoryFont
    cell.selectedTextColor = selectedCategoryTextColor
    cell.unselectedTextColor = unselectedCategoryTextColor
    cell.unselectedBackgroundColor = unselectedCategoryBackgroundColor
    cell.loadCategory(category(forIndexPath: indexPath), orientation: orientation)
    cell.isSelected = (selectedCategory == cell.category)
    return cell
  }

  // MARK: - UICollectionViewDelegate overrides

  public override func collectionView(
    _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
  {
    let cell = collectionView.cellForItem(at: indexPath) as! ToolboxCategoryListViewCell

    if selectedCategory == cell.category {
      // If the category has already been selected, de-select it
      self.selectedCategory = nil
      delegate?.toolboxCategoryListViewControllerDidDeselectCategory(self)
    } else {
      // Select the new category
      self.selectedCategory = cell.category

      if let category = cell.category {
        delegate?.toolboxCategoryListViewController(self, didSelectCategory: category)
      }
    }
  }

  // MARK: - Private

  fileprivate func indexPath(forCategory category: Toolbox.Category?) -> IndexPath? {
    if toolboxLayout == nil || category == nil {
      return nil
    }

    for i in 0 ..< toolboxLayout!.categoryLayoutCoordinators.count {
      if toolboxLayout!.categoryLayoutCoordinators[i].workspaceLayout.workspace == category {
        return IndexPath(row: i, section: 0)
      }
    }
    return nil
  }

  fileprivate func category(forIndexPath indexPath: IndexPath) -> Toolbox.Category {
    return toolboxLayout!.categoryLayoutCoordinators[(indexPath as NSIndexPath).row].workspaceLayout.workspace
      as! Toolbox.Category
  }
}

extension ToolboxCategoryListViewController: UICollectionViewDelegateFlowLayout {
  // MARK: - UICollectionViewDelegateFlowLayout implementation

  public func collectionView(_ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath) -> CGSize
  {
    let indexedCategory = category(forIndexPath: indexPath)
    let size = ToolboxCategoryListViewCell.sizeRequired(forCategory: indexedCategory, font: categoryFont)
    return size
  }
}

// MARK: - ToolboxCategoryListViewCell (Class)

/**
 An individual cell category list view cell.
*/
@objc(BKYToolboxCategoryListViewCell)
private class ToolboxCategoryListViewCell: UICollectionViewCell {
  static let ReusableCellIdentifier = "ToolboxCategoryListViewCell"

  private let kColorTagViewWidth = CGFloat(8)
  private let kIconSize = CGSize(width: 25, height: 25)

  /// The category this cell represents
  var category: Toolbox.Category?

  /// Label for the category name
  let nameLabel = UILabel()

  /// Image for the category icon
  let iconView = UIImageView()

  /// View representing the category's color
  let colorTagView = UIView()

  var selectedTextColor: UIColor?
  var unselectedBackgroundColor: UIColor?
  var unselectedTextColor: UIColor?

  override var isSelected: Bool {
    didSet {
      backgroundColor = isSelected ? category?.color : unselectedBackgroundColor
      nameLabel.textColor = isSelected ? selectedTextColor : unselectedTextColor
    }
  }

  // MARK: - Initializers

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureSubviews()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureSubviews()
  }

  // MARK: - Super

  override func prepareForReuse() {
    nameLabel.text = ""
    iconView.image = nil
    colorTagView.backgroundColor = UIColor.clear
    isSelected = false
  }

  // MARK: - Private

  func configureSubviews() {
    self.contentView.addSubview(colorTagView)
    self.contentView.addSubview(iconView)
    self.contentView.addSubview(nameLabel)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let contentViewWidth = self.contentView.frame.width
    let contentViewHeight = self.contentView.frame.height
    
    colorTagView.frame = CGRect(x: 0, y: 0, width: kColorTagViewWidth, height: contentViewHeight)
    
    iconView.frame = CGRect(x: colorTagView.frame.maxX + 10, y: (contentViewHeight-kIconSize.height)/2.0,
                            width: kIconSize.width, height: kIconSize.height)
    
    nameLabel.sizeToFit()
    let labelX = iconView.frame.maxX + 10
    let labelHeight = nameLabel.frame.height
    nameLabel.frame = CGRect(x: labelX, y: (contentViewHeight-labelHeight)/2.0,
                             width: contentViewWidth-labelX, height: labelHeight)
  }

  // MARK: - Private

  func loadCategory(_ category: Toolbox.Category, orientation: ToolboxCategoryListViewController.Orientation) {
    self.category = category

    colorTagView.backgroundColor = category.color
    iconView.image = category.icon
    nameLabel.text = category.name
  }

  static func sizeRequired(forCategory category: Toolbox.Category, font: UIFont) -> CGSize {
    return CGSize(width: ToolboxCategoryListViewController.ToolboxWidth, height: 50)
  }
}
