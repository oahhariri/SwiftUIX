//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

import Swift
import SwiftUI
import UIKit

/// A view that paginates its children along a given axis.
public struct PaginationView<Page: View>: View {
    @usableFromInline
    let pages: [Page]
    @usableFromInline
    let axis: Axis
    @usableFromInline
    let transitionStyle: UIPageViewController.TransitionStyle
    @usableFromInline
    let showsIndicators: Bool
    
    @usableFromInline
    var pageIndicatorAlignment: Alignment
    @usableFromInline
    var cyclesPages: Bool = false
    @usableFromInline
    var initialPageIndex: Int?
    @usableFromInline
    var currentPageIndex: Binding<Int>?
    
    /// The current page index internally used by `PaginationView`.
    /// Never access this directly, it is marked public as a workaround to a compiler bug.
    @inlinable
    @State public var _currentPageIndex = 0
    
    /// Never access this directly, it is marked public as a workaround to a compiler bug.
    @inlinable
    @DelayedState public var _progressionController: ProgressionController?
    
    @inlinable
    public init(
        pages: [Page],
        axis: Axis = .horizontal,
        transitionStyle: UIPageViewController.TransitionStyle = .scroll,
        showsIndicators: Bool = true
    ) {
        self.pages = pages
        self.axis = axis
        self.transitionStyle = transitionStyle
        self.showsIndicators = showsIndicators
        
        switch axis {
            case .horizontal:
                self.pageIndicatorAlignment = .center
            case .vertical:
                self.pageIndicatorAlignment = .leading
        }
    }
    
    @inlinable
    public init(
        axis: Axis = .horizontal,
        transitionStyle: UIPageViewController.TransitionStyle = .scroll,
        showsIndicators: Bool = true,
        @ArrayBuilder<Page> content: () -> [Page]
    ) {
        self.init(
            pages: content(),
            axis: axis,
            transitionStyle: transitionStyle,
            showsIndicators: showsIndicators
        )
    }
    
    @inlinable
    public var body: some View {
        ZStack(alignment: pageIndicatorAlignment) {
            _PaginationView(
                pages: pages,
                axis: axis,
                transitionStyle: transitionStyle,
                showsIndicators: showsIndicators,
                pageIndicatorAlignment: pageIndicatorAlignment,
                cyclesPages: cyclesPages,
                initialPageIndex: initialPageIndex,
                currentPageIndex: currentPageIndex ?? $_currentPageIndex,
                progressionController: $_progressionController
            )
            
            if showsIndicators && (axis == .vertical || pageIndicatorAlignment != .center) {
                PageControl(
                    numberOfPages: pages.count,
                    currentPage: currentPageIndex ?? $_currentPageIndex
                ).rotationEffect(
                    axis == .vertical
                        ? .init(degrees: 90)
                        : .init(degrees: 0)
                )
            }
        }
        .environment(\.progressionController, _progressionController)
    }
}

extension PaginationView {
    @inlinable
    public init<Data, ID>(
        axis: Axis = .horizontal,
        transitionStyle: UIPageViewController.TransitionStyle = .scroll,
        showsIndicators: Bool = true,
        @ViewBuilder pages: () -> ForEach<Data, ID, Page>
    ) {
        let _pages = pages()
        
        self.init(
            pages: _pages.data.map(_pages.content),
            axis: axis,
            transitionStyle: transitionStyle,
            showsIndicators: showsIndicators
        )
    }
}

// MARK: - API -

extension PaginationView {
    @inlinable
    public func pageIndicatorAlignment(_ alignment: Alignment) -> Self {
        then({ $0.pageIndicatorAlignment = alignment })
    }
    
    @inlinable
    public func cyclesPages(_ cyclesPages: Bool) -> Self {
        then({ $0.cyclesPages = cyclesPages })
    }
}

extension PaginationView {
    @inlinable
    public func initialPageIndex(_ initialPageIndex: Int) -> Self {
        then({ $0.initialPageIndex = initialPageIndex })
    }
    
    @inlinable
    public func currentPageIndex(_ currentPageIndex: Binding<Int>) -> Self {
        then({ $0.currentPageIndex = currentPageIndex })
    }
}

#endif
