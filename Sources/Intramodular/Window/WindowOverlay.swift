//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || os(macOS) || os(tvOS) || targetEnvironment(macCatalyst)

import Swift
import SwiftUI

/// A window overlay for SwiftUI.
@usableFromInline
struct WindowOverlay<Content: View>: AppKitOrUIKitViewControllerRepresentable {
    @usableFromInline
    let content: Content
    
    @usableFromInline
    let isKeyAndVisible: Binding<Bool>
    
    @usableFromInline
    let theme: UIUserInterfaceStyle
    
    @usableFromInline
    init(content: Content, isKeyAndVisible: Binding<Bool>,theme:UIUserInterfaceStyle) {
        self.content = content
        self.isKeyAndVisible = isKeyAndVisible
        self.theme = theme
    }
    
    @usableFromInline
    func makeAppKitOrUIKitViewController(context: Context) -> AppKitOrUIKitViewControllerType {
        .init(content: content, isKeyAndVisible: isKeyAndVisible, theme: theme)
    }
    
    @usableFromInline
    func updateAppKitOrUIKitViewController(_ viewController: AppKitOrUIKitViewControllerType, context: Context) {
        viewController.isKeyAndVisible = isKeyAndVisible
        viewController.content = content
        viewController.theme = theme
        viewController.updateWindow()
        
        #if os(iOS)
        if let window = viewController.contentWindow {
            window.overrideUserInterfaceStyle = context.environment.colorScheme == .light ? .light : .dark
            window.rootViewController?.overrideUserInterfaceStyle = window.overrideUserInterfaceStyle
        }
        #endif
    }
    
    @usableFromInline
    static func dismantleAppKitOrUIKitViewController(_ viewController: AppKitOrUIKitViewControllerType, coordinator: Coordinator) {
        DispatchQueue.global(qos: .userInitiated).async {
            // do something
            viewController.isKeyAndVisible.wrappedValue = false
            viewController.updateWindow()
            viewController.contentWindow = nil
        }
    }
}

extension WindowOverlay {
    @usableFromInline
    class AppKitOrUIKitViewControllerType: AppKitOrUIKitViewController {
        @usableFromInline
        var content: Content {
            didSet {
                contentWindow?.rootView = content
            }
        }
        
        @usableFromInline
        var isKeyAndVisible: Binding<Bool>
        
        @usableFromInline
        var theme: UIUserInterfaceStyle
        
        @usableFromInline
        var contentWindow: AppKitOrUIKitHostingWindow<Content>?
        #if os(macOS)
        @usableFromInline
        var contentWindowController: NSWindowController?
        #endif
        
        @usableFromInline
        init(content: Content, isKeyAndVisible: Binding<Bool>,theme:UIUserInterfaceStyle) {
            self.content = content
            self.isKeyAndVisible = isKeyAndVisible
            self.theme = theme
            super.init(nibName: nil, bundle: nil)
            
            #if os(macOS)
            view = NSView()
            #endif
        }
        
        @usableFromInline
        func updateWindow() {
            if let contentWindow = contentWindow, contentWindow.isHidden == !isKeyAndVisible.wrappedValue {
                return
            }
            
            if isKeyAndVisible.wrappedValue {
                #if !os(macOS)
                guard let window = view?.window, let windowScene = window.windowScene else {
                    return
                }
                #endif
                
                #if os(macOS)
                let contentWindow = self.contentWindow ?? AppKitOrUIKitHostingWindow(rootView: content)
                #else
                let contentWindow = self.contentWindow ?? AppKitOrUIKitHostingWindow(
                    windowScene: windowScene,
                    rootView: content
                )
                #endif
                
                if self.contentWindow == nil {
                    #if os(macOS)
                    NotificationCenter.default.addObserver(self, selector: #selector(Self.windowWillClose(_:)), name: NSWindow.willCloseNotification, object: nil)
                    #endif
                }
                
                self.contentWindow = contentWindow
                #if os(macOS)
                self.contentWindowController = .init(window: contentWindow)
                #endif
                
                contentWindow.rootView = content
                contentWindow.isKeyAndVisible = isKeyAndVisible
                
                #if os(macOS)
                contentWindow.title = ""
                contentWindowController?.showWindow(self)
                #else
                contentWindow.canResizeToFitContent = true
                contentWindow.isHidden = false
                contentWindow.isUserInteractionEnabled = true
                contentWindow.windowLevel = .init(rawValue: window.windowLevel.rawValue + 1)
                contentWindow.overrideUserInterfaceStyle = theme
                contentWindow.makeKeyAndVisible()
                
                contentWindow.rootViewController?.view.setNeedsDisplay()
                #endif
            } else {
                #if os(macOS)
                contentWindow?.close()
                #else
                contentWindow?.isHidden = true
                contentWindow?.isUserInteractionEnabled = false
                contentWindow = nil
                #endif
            }
        }
        
        @usableFromInline
        @objc required dynamic init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        #if !os(macOS)
        @usableFromInline
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            
            updateWindow()
        }
        #endif
        
        #if os(macOS)
        @objc
        public func windowWillClose(_ notification: Notification?) {
            if (notification?.object as? AppKitOrUIKitHostingWindow<Content>) === contentWindow {
                isKeyAndVisible.wrappedValue = false
            }
        }
        #endif
    }
}

// MARK: - Helpers -

extension View {
    /// Makes a window key and visible when a given condition is true
    /// - Parameters:
    ///   - isKeyAndVisible: A binding to whether the window is key and visible.
    ///   - content: A closure returning the content of the window.
    public func windowOverlay<Content: View>(
        isKeyAndVisible: Binding<Bool>,
        theme: UIUserInterfaceStyle,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        background(WindowOverlay(content: content(), isKeyAndVisible: isKeyAndVisible, theme: theme))
    }
}

#endif
