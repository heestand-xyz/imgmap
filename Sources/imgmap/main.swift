import Cocoa
import Foundation
import ArgumentParser
import RenderKit
import PixelKit

enum ImgMapError: Error {
    case folderNotFound(String)
    case fileNotFolder(String)
    case renderFailed(String)
}

var didSetup: Bool = false
var didSetLib: Bool = false

func setup() {
    guard didSetLib else { return }
    guard !didSetup else { return }
    frameLoopRenderThread = .background
    PixelKit.main.render.engine.renderMode = .manual
    PixelKit.main.disableLogging()
    didSetup = true
}

func setLib(url: URL) {
    guard !didSetLib else { return }
    guard FileManager.default.fileExists(atPath: url.path) else { return }
    pixelKitMetalLibURL = url
    didSetLib = true
    setup()
}

struct Imgmap: ParsableCommand {
    
    @Argument()
    var folder: URL
    
    @Argument()
    var resolution: Resolution
    
    @Option(name: .shortAndLong, help: "PixelKit Metal Library")
    var metalLib: URL?
    
    @Option(name: .shortAndLong, help: "fill | aspectFit | aspectFill | custom")
    var placement: Placement?
    
    func run() throws {
        
        if let metalLib: URL = metalLib {
            setLib(url: metalLib)
        } else {
            setLib(url: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Code/Frameworks/Production/PixelKit/Resources/Metal Libs/PixelKitShaders-macOS.metallib"))
        }

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDir) else {
            throw ImgMapError.folderNotFound(folder.path)
        }
        guard isDir.boolValue else {
            throw ImgMapError.fileNotFolder(folder.path)
        }
        
        print("imgmap")
        
        let images: [(NSImage, String)] = try list(url: folder)
                
        for image in images {
            print("render", image.1)
            let pix = convert(image: image.0)
            let url = folder.appendingPathComponent("\(image.1)_\(resolution.name).png")
            try render(pix, to: url)
        }
        
    }
    
    func list(url: URL) throws -> [(NSImage, String)] {
        let names: [String] = try FileManager.default.contentsOfDirectory(atPath: url.path)
        var urls: [URL] = names.map { name -> URL in
            url.appendingPathComponent(name)
        }
        urls = urls.filter({ url -> Bool in
            ["png", "jpg", "tiff"].contains(url.pathExtension.lowercased())
        })
        return urls.compactMap { url -> (NSImage, String)? in
            guard let image = NSImage(contentsOf: url) else { return nil }
            let name: String = String(url.lastPathComponent.split(separator: ".").first!)
            return (image, name)
        }
    }
    
    func convert(image: NSImage) -> PIX {
        let imagePix = ImagePIX()
        imagePix.image = image
        let backgroundPix = ColorPIX(at: resolution)
        backgroundPix.color = .clear
        let blendPix = BlendPIX()
        blendPix.blendMode = .over
        blendPix.inputA = backgroundPix
        blendPix.inputB = imagePix
        blendPix.placement = placement ?? .custom
        return blendPix
    }
    
    func render(_ pix: PIX, to url: URL) throws {
        var outImg: NSImage?
        var rendering: Bool? = true
        startTic()
        loopTic(while: { rendering })
        let group = DispatchGroup()
        group.enter()
        try PixelKit.main.render.engine.manuallyRender {
            outImg = pix.renderedImage
            group.leave()
        }
        group.wait()
        guard let img: NSImage = outImg else {
            rendering = nil
            throw ImgMapError.renderFailed("render failed")
        }
        rendering = false
        let outData: Data = NSBitmapImageRep(data: img.tiffRepresentation!)!.representation(using: .png, properties: [:])!
        try outData.write(to: url)
//        _ = try shellOut(to: .openFile(at: url.path))
        rendering = nil
        endTic()
    }

    func startTic() {
        print("...\r", terminator: "")
        fflush(stdout)
    }
    
    func loopTic(while active: @escaping () -> (Bool?)) {
        var i = 0
        self.bgTimer(0.01) {
            let state: Bool? = active()
            guard state != nil else { return false }
            i = (i + 1) % 3
            self.gohstPrint(String.init(repeating: state == true ? "." : ":", count: i + 1) + String.init(repeating: " ", count: 3 - i))
            return true
        }
    }
    
    func gohstPrint(_ message: String) {
        print("\(message)\r", terminator: "")
        fflush(stdout)
    }
    
    func endTic() {
        print("   \r", terminator: "")
    }
    
    func bgTimer(_ duration: Double, _ callback: @escaping () -> (Bool)) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .milliseconds(Int(duration * 1_000.0))) {
            guard callback() else { return }
            self.bgTimer(duration, callback)
        }
    }
    
}

Imgmap.main()
