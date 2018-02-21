//
//  HMACAlogrithm.swift
//  ZBeaconKitExample
//
//  Created by R3alFr3e on 2/21/18.
//  Copyright © 2018 ZOYI. All rights reserved.
//

import Foundation

enum HMACAlgorithm {
  case md5, sha1, sha224, sha256, sha384, sha512
  
  func toCCHmacAlgorithm() -> CCHmacAlgorithm {
    var result: Int = 0
    switch self {
    case .md5:
      result = kCCHmacAlgMD5
    case .sha1:
      result = kCCHmacAlgSHA1
    case .sha224:
      result = kCCHmacAlgSHA224
    case .sha256:
      result = kCCHmacAlgSHA256
    case .sha384:
      result = kCCHmacAlgSHA384
    case .sha512:
      result = kCCHmacAlgSHA512
    }
    return CCHmacAlgorithm(result)
  }
  
  func digestLength() -> Int {
    var result: CInt = 0
    switch self {
    case .md5:
      result = CC_MD5_DIGEST_LENGTH
    case .sha1:
      result = CC_SHA1_DIGEST_LENGTH
    case .sha224:
      result = CC_SHA224_DIGEST_LENGTH
    case .sha256:
      result = CC_SHA256_DIGEST_LENGTH
    case .sha384:
      result = CC_SHA384_DIGEST_LENGTH
    case .sha512:
      result = CC_SHA512_DIGEST_LENGTH
    }
    return Int(result)
  }
}

extension String {
  func hmac(_ algorithm: HMACAlgorithm, key: String) -> String {
    let cKey = key.cString(using: String.Encoding.utf8)
    let cData = self.cString(using: String.Encoding.utf8)
    var result = [CUnsignedChar](repeating: 0, count: Int(algorithm.digestLength()))
    CCHmac(algorithm.toCCHmacAlgorithm(), cKey!, Int(strlen(cKey!)), cData!, Int(strlen(cData!)), &result)
    let hmacData:Data = Data(bytes: UnsafePointer<UInt8>(result), count: (Int(algorithm.digestLength())))
    let hmacBase64 = hmacData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength76Characters)
    return String(hmacBase64)
  }
}
