//
//  HMACAlgorithm.swift
//  ZBeacon
//
//  Created by 이수완 on 2016. 10. 12..
//  Copyright © 2016년 ZOYI. All rights reserved.
//

import Foundation

enum HMACAlgorithm {
  case MD5, SHA1, SHA224, SHA256, SHA384, SHA512

  func toCCHmacAlgorithm() -> CCHmacAlgorithm {
    var result: Int = 0
    switch self {
    case .MD5:
      result = kCCHmacAlgMD5
    case .SHA1:
      result = kCCHmacAlgSHA1
    case .SHA224:
      result = kCCHmacAlgSHA224
    case .SHA256:
      result = kCCHmacAlgSHA256
    case .SHA384:
      result = kCCHmacAlgSHA384
    case .SHA512:
      result = kCCHmacAlgSHA512
    }
    return CCHmacAlgorithm(result)
  }

  func digestLength() -> Int {
    var result: CInt = 0
    switch self {
    case .MD5:
      result = CC_MD5_DIGEST_LENGTH
    case .SHA1:
      result = CC_SHA1_DIGEST_LENGTH
    case .SHA224:
      result = CC_SHA224_DIGEST_LENGTH
    case .SHA256:
      result = CC_SHA256_DIGEST_LENGTH
    case .SHA384:
      result = CC_SHA384_DIGEST_LENGTH
    case .SHA512:
      result = CC_SHA512_DIGEST_LENGTH
    }
    return Int(result)
  }
}

extension String {
  func hmac(algorithm: HMACAlgorithm, key: String) -> String {
    let cKey = key.cStringUsingEncoding(NSUTF8StringEncoding)
    let cData = self.cStringUsingEncoding(NSUTF8StringEncoding)
    var result = [CUnsignedChar](count: Int(algorithm.digestLength()), repeatedValue: 0)
    CCHmac(algorithm.toCCHmacAlgorithm(), cKey!, strlen(cKey!), cData!, strlen(cData!), &result)
    var hmacData:NSData = NSData(bytes: result, length: (Int(algorithm.digestLength())))
    var hmacBase64 = hmacData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding76CharacterLineLength)
    return String(hmacBase64)
  }
}
