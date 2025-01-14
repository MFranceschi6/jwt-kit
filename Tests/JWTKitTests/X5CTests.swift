import XCTest
import Foundation
#if os(Linux)
import FoundationNetworking
#endif
@testable import JWTKit

/// Test the x5c verification abilities of JWTSigners.
///
/// In these tests, there are 4 certificates:
/// - Root
/// - Intermediate
/// - Leaf
/// - Leaf expired
///
/// All tokens in these tests have been signed with the "Leaf" private key.
/// "Root" is the trusted, self-signed certificate. "Intermediate" is signed by
/// "Root" and "Leaf" is signed by "Intermediate."
///
/// "Leaf expired" has the same private key as "Leaf" but is meant to expire Oct 30 16:06:22 2022 GMT.
///
/// Only tokens with an x5c chain that starts with "Leaf"
/// and ends in either "Intermediate" or "Root" should
/// successfully be verified.
final class X5CTests: XCTestCase {
    let verifier = try! X5CVerifier(rootCertificates: [
        // Trusted root:
            """
            -----BEGIN CERTIFICATE-----
            MIIB6zCCAXGgAwIBAgIJAI3sc/f0ktHTMAoGCCqGSM49BAMCMBsxGTAXBgNVBAMM
            EHJvb3QuZXhhbXBsZS5jb20wIBcNMjIxMDMwMDAzNDQ0WhgPNDc2MDA5MjYwMDM0
            NDRaMBsxGTAXBgNVBAMMEHJvb3QuZXhhbXBsZS5jb20wdjAQBgcqhkjOPQIBBgUr
            gQQAIgNiAAR/hn7tMdHbB/aKHj6a6wA8kmTlNMOdZxihlv/nxGm2AvwmcwxXN3Uu
            7fneNNpisfFZ9HwDCxQ0KNRsc65f26JKF3kF5/hiMQ7Dwk/Fu7chs3rTLM+PplIc
            UpHJQeX3hcajfzB9MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFDGEj26owWgw
            h0OfL7X+Xmwlw+NTMEsGA1UdIwREMEKAFDGEj26owWgwh0OfL7X+Xmwlw+NToR+k
            HTAbMRkwFwYDVQQDDBByb290LmV4YW1wbGUuY29tggkAjexz9/SS0dMwCgYIKoZI
            zj0EAwIDaAAwZQIxAPz8R8IbtBDF5yk2v5tZupPCn6O7yIf9ujSVTv+53S/b+6ot
            ZbptUuczVBg1TpuA3AIwCdqNUVCHMRWw3hfDoNkQ0WNwkq7BRzfPKV992iqPJ3IT
            X0KocayNdxiyK5+W61oV
            -----END CERTIFICATE-----
            """
    ])

    func check(
        token: String
    ) throws {
        _ = try verifier.verifyJWS(
            token,
            as: TokenPayload.self
        )
    }

    /// x5c: [leaf, intermediate, root]
    ///
    /// Should pass validation.
    func testValidChain() throws {
        XCTAssertNoThrow(try check(token: validToken), "Valid certificate chain was not verified.")
    }

    /// x5c: [leaf, root]
    ///
    /// Should fail validation.
    func testMissingIntermediate() throws {
        XCTAssertThrowsError(try check(token: missingIntermediateToken), "Missing intermediate cert should throw an error.")
    }

    /// x5c: [leaf, intermediate]
    ///
    /// Should pass validation.
    ///
    /// RFC 5280, section 6 (https://datatracker.ietf.org/doc/html/rfc5280#section-6.1)
    /// says:
    /// > When the trust anchor is provided in the form of a self-signed
    /// > certificate, this self-signed certificate is not included as part of
    /// > the prospective certification path.
    ///
    /// Some providers do include the root certificate as
    /// the final element in the chain, but the above RFC
    /// seems to say it's not necessary.
    func testMissingRoot() throws {
        XCTAssertNoThrow(try check(token: validToken), "Missing root cert is fine, since we know what root we expect.")
    }

    /// x5c: [intermediate, root]
    ///
    /// Should fail validation.
    func testMissingLeaf() throws {
        XCTAssertThrowsError(try check(token: missingLeafToken), "Missing leaf cert should throw an error.")
    }

    /// x5c: [root]
    ///
    /// Should fail validation.
    func testMissingLeafAndIntermediate() throws {
        XCTAssertThrowsError(try check(token: missingLeafAndIntermediateToken), "Missing leaf/intermediate cert should throw an error.")
    }

    /// x5c: [leaf]
    ///
    /// Should fail validation.
    func testMissingIntermediateAndRoot() throws {
        XCTAssertThrowsError(try check(token: missingIntermediateAndRootToken), "Missing intermediate/root cert should throw an error.")
    }

    /// x5c: [expired_leaf, intermediate, root]
    ///
    /// Should fail validation because leaf is epxired.
    func testExpiredLeaf() throws {
        XCTAssertThrowsError(try check(token: expiredLeafToken), "Expired leaf token is invalid.")
    }

    /// x5c: [leaf, intermediate, root]
    ///
    /// Should fail validation because it's not cool!
    ///
    /// This is a test to make sure that the claims actually
    /// get verified.
    func testValidButNotCool() throws {
        XCTAssertThrowsError(try check(token: validButNotCoolToken), "Token isn't cool. Claims weren't verified.")
    }

    // Auto-generated:
    let validToken = """
        eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsIng1YyI6WyJNSUlCYXpDQjhnSUpBSmppU3ArRXhBalNNQWtHQnlxR1NNNDlCQUV3SXpFaE1COEdBMVVFQXd3WWFXNTBaWEp0WldScFlYUmxMbVY0WVcxd2JHVXVZMjl0TUNBWERUSXlNVEF6TURBeE1UWXhNVm9ZRHpRM05qQXdPVEkyTURFeE5qRXhXakFiTVJrd0Z3WURWUVFEREJCc1pXRm1MbVY0WVcxd2JHVXVZMjl0TUhZd0VBWUhLb1pJemowQ0FRWUZLNEVFQUNJRFlnQUV5aSs3dGJkSEVJTCtjUlNYOG5IZk80SVc5bFZ4bGlramVPTTNqNWhSaE94OGhna3lKa0pYQ0xPNzZMTEJacEhjYjQvaDlSY2xWRkh2cjBUQ3cwOXppb0lrclhFd0lRbk9MSXU1OVY0czJCRG5MRVVzYXU5a1lKQmNEeUdOcTRiSU1Ba0dCeXFHU000OUJBRURhUUF3WmdJeEFQK25xbXhYa3JPYXZCYkRsOTlsalhEWjVXZlVJY3hxSXF3L0NqakxnbmVZTmZoKzYzK0FxTi93cit2Z0h0WVRyd0l4QU5sc1p3WHQxRnpnZmE2TndSK2V3eE1lUnhVNjAxcmJ1QjZNaXJOY1dlUjNKT3pIN2V4REV2OVNiNnpiVi9sN1dRPT0iLCJNSUlCbFRDQ0FSeWdBd0lCQWdJSkFKTFRvWW1NOHpZK01Ba0dCeXFHU000OUJBRXdHekVaTUJjR0ExVUVBd3dRY205dmRDNWxlR0Z0Y0d4bExtTnZiVEFnRncweU1qRXdNekF3TVRFMU1qZGFHQTgwTnpZd01Ea3lOakF4TVRVeU4xb3dJekVoTUI4R0ExVUVBd3dZYVc1MFpYSnRaV1JwWVhSbExtVjRZVzF3YkdVdVkyOXRNSFl3RUFZSEtvWkl6ajBDQVFZRks0RUVBQ0lEWWdBRWtYQlkrU3JPQVNPV3R2TVUyOGVCQk9rdVd5R1BhbFExRVNlRXZqelNmTFR0TlhBdVZSNDJNNmFmdERVQjZFU2RZNE5MQ3JTelBNbUlLQ3Z5Y3lVbi8vZ1VJcmJlcGF2akVOMHBocWM3UEVtbmJNM0NnSWxSVmJIT3FpYTIxWXNhb3lNd0lUQVBCZ05WSFJNQkFmOEVCVEFEQVFIL01BNEdBMVVkRHdFQi93UUVBd0lDQkRBSkJnY3Foa2pPUFFRQkEyZ0FNR1VDTVFDbWxBN0ZxSmxmMEdSZnYzY1UxTUp0L2dlUWdKeVA0L2NEV1pGd3k5bnYvV1Z3cVYvdFY1N0VvSko1L0ZLYmZlY0NNQ2NLMDloKzJmcWhjYUFBVk1ORGhKMVFlcDFmaUZPR0o4U2pITjhVRDdqckJSTmZEUXFzKytZNXBvZ2xIa2hINmc9PSIsIk1JSUI2ekNDQVhHZ0F3SUJBZ0lKQUkzc2MvZjBrdEhUTUFvR0NDcUdTTTQ5QkFNQ01Cc3hHVEFYQmdOVkJBTU1FSEp2YjNRdVpYaGhiWEJzWlM1amIyMHdJQmNOTWpJeE1ETXdNREF6TkRRMFdoZ1BORGMyTURBNU1qWXdNRE0wTkRSYU1Cc3hHVEFYQmdOVkJBTU1FSEp2YjNRdVpYaGhiWEJzWlM1amIyMHdkakFRQmdjcWhrak9QUUlCQmdVcmdRUUFJZ05pQUFSL2huN3RNZEhiQi9hS0hqNmE2d0E4a21UbE5NT2RaeGlobHYvbnhHbTJBdndtY3d4WE4zVXU3Zm5lTk5waXNmRlo5SHdEQ3hRMEtOUnNjNjVmMjZKS0Yza0Y1L2hpTVE3RHdrL0Z1N2NoczNyVExNK1BwbEljVXBISlFlWDNoY2FqZnpCOU1BOEdBMVVkRXdFQi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZER0VqMjZvd1dnd2gwT2ZMN1grWG13bHcrTlRNRXNHQTFVZEl3UkVNRUtBRkRHRWoyNm93V2d3aDBPZkw3WCtYbXdsdytOVG9SK2tIVEFiTVJrd0Z3WURWUVFEREJCeWIyOTBMbVY0WVcxd2JHVXVZMjl0Z2drQWpleHo5L1NTMGRNd0NnWUlLb1pJemowRUF3SURhQUF3WlFJeEFQejhSOElidEJERjV5azJ2NXRadXBQQ242Tzd5SWY5dWpTVlR2KzUzUy9iKzZvdFpicHRVdWN6VkJnMVRwdUEzQUl3Q2RxTlVWQ0hNUld3M2hmRG9Oa1EwV053a3E3QlJ6ZlBLVjk5MmlxUEozSVRYMEtvY2F5TmR4aXlLNStXNjFvViJdfQ.eyJjb29sIjp0cnVlfQ.5GPJtDv4MWOy-WZpjsuO-nLnkL4OMvjjR60q3DnrXVNYH6rhyWpORHVhiPuamyrXtpdSIkHn6eaSW7bRHyPfNlnGcxhLYsKrfRGIn1qS-Excu0DjrDbOtwbtJ09sKzy_
        """
    let missingIntermediateToken = """
        eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsIng1YyI6WyJNSUlCYXpDQjhnSUpBSmppU3ArRXhBalNNQWtHQnlxR1NNNDlCQUV3SXpFaE1COEdBMVVFQXd3WWFXNTBaWEp0WldScFlYUmxMbVY0WVcxd2JHVXVZMjl0TUNBWERUSXlNVEF6TURBeE1UWXhNVm9ZRHpRM05qQXdPVEkyTURFeE5qRXhXakFiTVJrd0Z3WURWUVFEREJCc1pXRm1MbVY0WVcxd2JHVXVZMjl0TUhZd0VBWUhLb1pJemowQ0FRWUZLNEVFQUNJRFlnQUV5aSs3dGJkSEVJTCtjUlNYOG5IZk80SVc5bFZ4bGlramVPTTNqNWhSaE94OGhna3lKa0pYQ0xPNzZMTEJacEhjYjQvaDlSY2xWRkh2cjBUQ3cwOXppb0lrclhFd0lRbk9MSXU1OVY0czJCRG5MRVVzYXU5a1lKQmNEeUdOcTRiSU1Ba0dCeXFHU000OUJBRURhUUF3WmdJeEFQK25xbXhYa3JPYXZCYkRsOTlsalhEWjVXZlVJY3hxSXF3L0NqakxnbmVZTmZoKzYzK0FxTi93cit2Z0h0WVRyd0l4QU5sc1p3WHQxRnpnZmE2TndSK2V3eE1lUnhVNjAxcmJ1QjZNaXJOY1dlUjNKT3pIN2V4REV2OVNiNnpiVi9sN1dRPT0iLCJNSUlCNnpDQ0FYR2dBd0lCQWdJSkFJM3NjL2Ywa3RIVE1Bb0dDQ3FHU000OUJBTUNNQnN4R1RBWEJnTlZCQU1NRUhKdmIzUXVaWGhoYlhCc1pTNWpiMjB3SUJjTk1qSXhNRE13TURBek5EUTBXaGdQTkRjMk1EQTVNall3TURNME5EUmFNQnN4R1RBWEJnTlZCQU1NRUhKdmIzUXVaWGhoYlhCc1pTNWpiMjB3ZGpBUUJnY3Foa2pPUFFJQkJnVXJnUVFBSWdOaUFBUi9objd0TWRIYkIvYUtIajZhNndBOGttVGxOTU9kWnhpaGx2L254R20yQXZ3bWN3eFhOM1V1N2ZuZU5OcGlzZkZaOUh3REN4UTBLTlJzYzY1ZjI2SktGM2tGNS9oaU1RN0R3ay9GdTdjaHMzclRMTStQcGxJY1VwSEpRZVgzaGNhamZ6QjlNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdIUVlEVlIwT0JCWUVGREdFajI2b3dXZ3doME9mTDdYK1htd2x3K05UTUVzR0ExVWRJd1JFTUVLQUZER0VqMjZvd1dnd2gwT2ZMN1grWG13bHcrTlRvUitrSFRBYk1Sa3dGd1lEVlFRRERCQnliMjkwTG1WNFlXMXdiR1V1WTI5dGdna0FqZXh6OS9TUzBkTXdDZ1lJS29aSXpqMEVBd0lEYUFBd1pRSXhBUHo4UjhJYnRCREY1eWsydjV0WnVwUENuNk83eUlmOXVqU1ZUdis1M1MvYis2b3RaYnB0VXVjelZCZzFUcHVBM0FJd0NkcU5VVkNITVJXdzNoZkRvTmtRMFdOd2txN0JSemZQS1Y5OTJpcVBKM0lUWDBLb2NheU5keGl5SzUrVzYxb1YiXX0.eyJjb29sIjp0cnVlfQ.Z3TFhBVy73ef-hC_RHv4Wu-5dYtUY_I-gcGD20so7_bww5sZFpkQHy2FKYWUyTv6lYeaOU72W0ZyD-hyvSBfjwYUXupMnH3SP_8TXJqxbFXdwjvMJsLAZeih_tocQ2U7
        """
    let missingRootToken = """
        eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsIng1YyI6WyJNSUlCYXpDQjhnSUpBSmppU3ArRXhBalNNQWtHQnlxR1NNNDlCQUV3SXpFaE1COEdBMVVFQXd3WWFXNTBaWEp0WldScFlYUmxMbVY0WVcxd2JHVXVZMjl0TUNBWERUSXlNVEF6TURBeE1UWXhNVm9ZRHpRM05qQXdPVEkyTURFeE5qRXhXakFiTVJrd0Z3WURWUVFEREJCc1pXRm1MbVY0WVcxd2JHVXVZMjl0TUhZd0VBWUhLb1pJemowQ0FRWUZLNEVFQUNJRFlnQUV5aSs3dGJkSEVJTCtjUlNYOG5IZk80SVc5bFZ4bGlramVPTTNqNWhSaE94OGhna3lKa0pYQ0xPNzZMTEJacEhjYjQvaDlSY2xWRkh2cjBUQ3cwOXppb0lrclhFd0lRbk9MSXU1OVY0czJCRG5MRVVzYXU5a1lKQmNEeUdOcTRiSU1Ba0dCeXFHU000OUJBRURhUUF3WmdJeEFQK25xbXhYa3JPYXZCYkRsOTlsalhEWjVXZlVJY3hxSXF3L0NqakxnbmVZTmZoKzYzK0FxTi93cit2Z0h0WVRyd0l4QU5sc1p3WHQxRnpnZmE2TndSK2V3eE1lUnhVNjAxcmJ1QjZNaXJOY1dlUjNKT3pIN2V4REV2OVNiNnpiVi9sN1dRPT0iLCJNSUlCbFRDQ0FSeWdBd0lCQWdJSkFKTFRvWW1NOHpZK01Ba0dCeXFHU000OUJBRXdHekVaTUJjR0ExVUVBd3dRY205dmRDNWxlR0Z0Y0d4bExtTnZiVEFnRncweU1qRXdNekF3TVRFMU1qZGFHQTgwTnpZd01Ea3lOakF4TVRVeU4xb3dJekVoTUI4R0ExVUVBd3dZYVc1MFpYSnRaV1JwWVhSbExtVjRZVzF3YkdVdVkyOXRNSFl3RUFZSEtvWkl6ajBDQVFZRks0RUVBQ0lEWWdBRWtYQlkrU3JPQVNPV3R2TVUyOGVCQk9rdVd5R1BhbFExRVNlRXZqelNmTFR0TlhBdVZSNDJNNmFmdERVQjZFU2RZNE5MQ3JTelBNbUlLQ3Z5Y3lVbi8vZ1VJcmJlcGF2akVOMHBocWM3UEVtbmJNM0NnSWxSVmJIT3FpYTIxWXNhb3lNd0lUQVBCZ05WSFJNQkFmOEVCVEFEQVFIL01BNEdBMVVkRHdFQi93UUVBd0lDQkRBSkJnY3Foa2pPUFFRQkEyZ0FNR1VDTVFDbWxBN0ZxSmxmMEdSZnYzY1UxTUp0L2dlUWdKeVA0L2NEV1pGd3k5bnYvV1Z3cVYvdFY1N0VvSko1L0ZLYmZlY0NNQ2NLMDloKzJmcWhjYUFBVk1ORGhKMVFlcDFmaUZPR0o4U2pITjhVRDdqckJSTmZEUXFzKytZNXBvZ2xIa2hINmc9PSJdfQ.eyJjb29sIjp0cnVlfQ.QkOoLXWqUGCSqX997z81-B1TmNMGSKZH2oTV7gbBnd2WCWZ1hhlK5OAoUZhlZCYZJWgeUI7eXv5HLxfdtgIx8T9Qo7KOzSfBWMhiM6zr8ghgqmEJbe-E3ZEG9TGLDDXU
        """
    let missingLeafToken = """
        eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsIng1YyI6WyJNSUlCbFRDQ0FSeWdBd0lCQWdJSkFKTFRvWW1NOHpZK01Ba0dCeXFHU000OUJBRXdHekVaTUJjR0ExVUVBd3dRY205dmRDNWxlR0Z0Y0d4bExtTnZiVEFnRncweU1qRXdNekF3TVRFMU1qZGFHQTgwTnpZd01Ea3lOakF4TVRVeU4xb3dJekVoTUI4R0ExVUVBd3dZYVc1MFpYSnRaV1JwWVhSbExtVjRZVzF3YkdVdVkyOXRNSFl3RUFZSEtvWkl6ajBDQVFZRks0RUVBQ0lEWWdBRWtYQlkrU3JPQVNPV3R2TVUyOGVCQk9rdVd5R1BhbFExRVNlRXZqelNmTFR0TlhBdVZSNDJNNmFmdERVQjZFU2RZNE5MQ3JTelBNbUlLQ3Z5Y3lVbi8vZ1VJcmJlcGF2akVOMHBocWM3UEVtbmJNM0NnSWxSVmJIT3FpYTIxWXNhb3lNd0lUQVBCZ05WSFJNQkFmOEVCVEFEQVFIL01BNEdBMVVkRHdFQi93UUVBd0lDQkRBSkJnY3Foa2pPUFFRQkEyZ0FNR1VDTVFDbWxBN0ZxSmxmMEdSZnYzY1UxTUp0L2dlUWdKeVA0L2NEV1pGd3k5bnYvV1Z3cVYvdFY1N0VvSko1L0ZLYmZlY0NNQ2NLMDloKzJmcWhjYUFBVk1ORGhKMVFlcDFmaUZPR0o4U2pITjhVRDdqckJSTmZEUXFzKytZNXBvZ2xIa2hINmc9PSIsIk1JSUI2ekNDQVhHZ0F3SUJBZ0lKQUkzc2MvZjBrdEhUTUFvR0NDcUdTTTQ5QkFNQ01Cc3hHVEFYQmdOVkJBTU1FSEp2YjNRdVpYaGhiWEJzWlM1amIyMHdJQmNOTWpJeE1ETXdNREF6TkRRMFdoZ1BORGMyTURBNU1qWXdNRE0wTkRSYU1Cc3hHVEFYQmdOVkJBTU1FSEp2YjNRdVpYaGhiWEJzWlM1amIyMHdkakFRQmdjcWhrak9QUUlCQmdVcmdRUUFJZ05pQUFSL2huN3RNZEhiQi9hS0hqNmE2d0E4a21UbE5NT2RaeGlobHYvbnhHbTJBdndtY3d4WE4zVXU3Zm5lTk5waXNmRlo5SHdEQ3hRMEtOUnNjNjVmMjZKS0Yza0Y1L2hpTVE3RHdrL0Z1N2NoczNyVExNK1BwbEljVXBISlFlWDNoY2FqZnpCOU1BOEdBMVVkRXdFQi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZER0VqMjZvd1dnd2gwT2ZMN1grWG13bHcrTlRNRXNHQTFVZEl3UkVNRUtBRkRHRWoyNm93V2d3aDBPZkw3WCtYbXdsdytOVG9SK2tIVEFiTVJrd0Z3WURWUVFEREJCeWIyOTBMbVY0WVcxd2JHVXVZMjl0Z2drQWpleHo5L1NTMGRNd0NnWUlLb1pJemowRUF3SURhQUF3WlFJeEFQejhSOElidEJERjV5azJ2NXRadXBQQ242Tzd5SWY5dWpTVlR2KzUzUy9iKzZvdFpicHRVdWN6VkJnMVRwdUEzQUl3Q2RxTlVWQ0hNUld3M2hmRG9Oa1EwV053a3E3QlJ6ZlBLVjk5MmlxUEozSVRYMEtvY2F5TmR4aXlLNStXNjFvViJdfQ.eyJjb29sIjp0cnVlfQ.Z07GFBWJef2Aw6JFZ37NjmDAyQb90Rl7EU37-z9XwCyMP-m40lcS9uSw2FE6K_RZSQlyPhBiZ_jkPOuLOerQuf9YFq-mrnA7ReFJJXNUJOFB5HsV28SATz2J6vZhwrNt
        """
    let missingLeafAndIntermediateToken = """
        eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsIng1YyI6WyJNSUlCNnpDQ0FYR2dBd0lCQWdJSkFJM3NjL2Ywa3RIVE1Bb0dDQ3FHU000OUJBTUNNQnN4R1RBWEJnTlZCQU1NRUhKdmIzUXVaWGhoYlhCc1pTNWpiMjB3SUJjTk1qSXhNRE13TURBek5EUTBXaGdQTkRjMk1EQTVNall3TURNME5EUmFNQnN4R1RBWEJnTlZCQU1NRUhKdmIzUXVaWGhoYlhCc1pTNWpiMjB3ZGpBUUJnY3Foa2pPUFFJQkJnVXJnUVFBSWdOaUFBUi9objd0TWRIYkIvYUtIajZhNndBOGttVGxOTU9kWnhpaGx2L254R20yQXZ3bWN3eFhOM1V1N2ZuZU5OcGlzZkZaOUh3REN4UTBLTlJzYzY1ZjI2SktGM2tGNS9oaU1RN0R3ay9GdTdjaHMzclRMTStQcGxJY1VwSEpRZVgzaGNhamZ6QjlNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdIUVlEVlIwT0JCWUVGREdFajI2b3dXZ3doME9mTDdYK1htd2x3K05UTUVzR0ExVWRJd1JFTUVLQUZER0VqMjZvd1dnd2gwT2ZMN1grWG13bHcrTlRvUitrSFRBYk1Sa3dGd1lEVlFRRERCQnliMjkwTG1WNFlXMXdiR1V1WTI5dGdna0FqZXh6OS9TUzBkTXdDZ1lJS29aSXpqMEVBd0lEYUFBd1pRSXhBUHo4UjhJYnRCREY1eWsydjV0WnVwUENuNk83eUlmOXVqU1ZUdis1M1MvYis2b3RaYnB0VXVjelZCZzFUcHVBM0FJd0NkcU5VVkNITVJXdzNoZkRvTmtRMFdOd2txN0JSemZQS1Y5OTJpcVBKM0lUWDBLb2NheU5keGl5SzUrVzYxb1YiXX0.eyJjb29sIjp0cnVlfQ.U45t7cnN8pJmRVDHB9NLd1KwMLzQcuK_KC1QJW2TgzpZixa475WFV_MrNDhV4GVFlljSNOYFyeT19Fft9bBfgzcPhMAyj74ncN-70Tqc_1FP7D97vhMFMXWdlHyOHk_n
        """
    let missingIntermediateAndRootToken = """
        eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsIng1YyI6WyJNSUlCYXpDQjhnSUpBSmppU3ArRXhBalNNQWtHQnlxR1NNNDlCQUV3SXpFaE1COEdBMVVFQXd3WWFXNTBaWEp0WldScFlYUmxMbVY0WVcxd2JHVXVZMjl0TUNBWERUSXlNVEF6TURBeE1UWXhNVm9ZRHpRM05qQXdPVEkyTURFeE5qRXhXakFiTVJrd0Z3WURWUVFEREJCc1pXRm1MbVY0WVcxd2JHVXVZMjl0TUhZd0VBWUhLb1pJemowQ0FRWUZLNEVFQUNJRFlnQUV5aSs3dGJkSEVJTCtjUlNYOG5IZk80SVc5bFZ4bGlramVPTTNqNWhSaE94OGhna3lKa0pYQ0xPNzZMTEJacEhjYjQvaDlSY2xWRkh2cjBUQ3cwOXppb0lrclhFd0lRbk9MSXU1OVY0czJCRG5MRVVzYXU5a1lKQmNEeUdOcTRiSU1Ba0dCeXFHU000OUJBRURhUUF3WmdJeEFQK25xbXhYa3JPYXZCYkRsOTlsalhEWjVXZlVJY3hxSXF3L0NqakxnbmVZTmZoKzYzK0FxTi93cit2Z0h0WVRyd0l4QU5sc1p3WHQxRnpnZmE2TndSK2V3eE1lUnhVNjAxcmJ1QjZNaXJOY1dlUjNKT3pIN2V4REV2OVNiNnpiVi9sN1dRPT0iXX0.eyJjb29sIjp0cnVlfQ.3x8O0n37YQMkbyVFryK5wviqm_RZLYPsYaSscRUo2SxIqfj9f0Wg8vjk9MxL2X2WiEk-n1Qu-MF8DI45qm7Vz9dEoN4ufbPxEbpz2NLghhkEdx7ewXwQA53euvDEC1Yr
        """
    let expiredLeafToken = """
        eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsIng1YyI6WyJNSUlCWnpDQjhBSUpBSmppU3ArRXhBalVNQWtHQnlxR1NNNDlCQUV3SXpFaE1COEdBMVVFQXd3WWFXNTBaWEp0WldScFlYUmxMbVY0WVcxd2JHVXVZMjl0TUI0WERUSXlNVEF5T1RFMk1EWXlNbG9YRFRJeU1UQXpNREUyTURZeU1sb3dHekVaTUJjR0ExVUVBd3dRYkdWaFppNWxlR0Z0Y0d4bExtTnZiVEIyTUJBR0J5cUdTTTQ5QWdFR0JTdUJCQUFpQTJJQUJNb3Z1N1czUnhDQy9uRVVsL0p4M3p1Q0Z2WlZjWllwSTNqak40K1lVWVRzZklZSk1pWkNWd2l6dStpeXdXYVIzRytQNGZVWEpWUlI3NjlFd3NOUGM0cUNKSzF4TUNFSnppeUx1ZlZlTE5nUTV5eEZMR3J2WkdDUVhBOGhqYXVHeURBSkJnY3Foa2pPUFFRQkEyY0FNR1FDTUdSZmxmUUZ3cm5BNXU0TmpZQm1jem5FckZKTm1sQTRwb0FtSExDendHTmJvQ09BV0daOFdIcXZpKzJncFZVbTVBSXdSTXd3WmtpYXhPOXkvTWNQMHRiMitBVmVjVU14Z2hZQjlBa01LZi9yWHZzaVVIWTl3RTVIRHAxK1NMQzhCdEZPIiwiTUlJQmxUQ0NBUnlnQXdJQkFnSUpBSkxUb1ltTTh6WStNQWtHQnlxR1NNNDlCQUV3R3pFWk1CY0dBMVVFQXd3UWNtOXZkQzVsZUdGdGNHeGxMbU52YlRBZ0Z3MHlNakV3TXpBd01URTFNamRhR0E4ME56WXdNRGt5TmpBeE1UVXlOMW93SXpFaE1COEdBMVVFQXd3WWFXNTBaWEp0WldScFlYUmxMbVY0WVcxd2JHVXVZMjl0TUhZd0VBWUhLb1pJemowQ0FRWUZLNEVFQUNJRFlnQUVrWEJZK1NyT0FTT1d0dk1VMjhlQkJPa3VXeUdQYWxRMUVTZUV2anpTZkxUdE5YQXVWUjQyTTZhZnREVUI2RVNkWTROTENyU3pQTW1JS0N2eWN5VW4vL2dVSXJiZXBhdmpFTjBwaHFjN1BFbW5iTTNDZ0lsUlZiSE9xaWEyMVlzYW95TXdJVEFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQTRHQTFVZER3RUIvd1FFQXdJQ0JEQUpCZ2NxaGtqT1BRUUJBMmdBTUdVQ01RQ21sQTdGcUpsZjBHUmZ2M2NVMU1KdC9nZVFnSnlQNC9jRFdaRnd5OW52L1dWd3FWL3RWNTdFb0pKNS9GS2JmZWNDTUNjSzA5aCsyZnFoY2FBQVZNTkRoSjFRZXAxZmlGT0dKOFNqSE44VUQ3anJCUk5mRFFxcysrWTVwb2dsSGtoSDZnPT0iLCJNSUlCNnpDQ0FYR2dBd0lCQWdJSkFJM3NjL2Ywa3RIVE1Bb0dDQ3FHU000OUJBTUNNQnN4R1RBWEJnTlZCQU1NRUhKdmIzUXVaWGhoYlhCc1pTNWpiMjB3SUJjTk1qSXhNRE13TURBek5EUTBXaGdQTkRjMk1EQTVNall3TURNME5EUmFNQnN4R1RBWEJnTlZCQU1NRUhKdmIzUXVaWGhoYlhCc1pTNWpiMjB3ZGpBUUJnY3Foa2pPUFFJQkJnVXJnUVFBSWdOaUFBUi9objd0TWRIYkIvYUtIajZhNndBOGttVGxOTU9kWnhpaGx2L254R20yQXZ3bWN3eFhOM1V1N2ZuZU5OcGlzZkZaOUh3REN4UTBLTlJzYzY1ZjI2SktGM2tGNS9oaU1RN0R3ay9GdTdjaHMzclRMTStQcGxJY1VwSEpRZVgzaGNhamZ6QjlNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdIUVlEVlIwT0JCWUVGREdFajI2b3dXZ3doME9mTDdYK1htd2x3K05UTUVzR0ExVWRJd1JFTUVLQUZER0VqMjZvd1dnd2gwT2ZMN1grWG13bHcrTlRvUitrSFRBYk1Sa3dGd1lEVlFRRERCQnliMjkwTG1WNFlXMXdiR1V1WTI5dGdna0FqZXh6OS9TUzBkTXdDZ1lJS29aSXpqMEVBd0lEYUFBd1pRSXhBUHo4UjhJYnRCREY1eWsydjV0WnVwUENuNk83eUlmOXVqU1ZUdis1M1MvYis2b3RaYnB0VXVjelZCZzFUcHVBM0FJd0NkcU5VVkNITVJXdzNoZkRvTmtRMFdOd2txN0JSemZQS1Y5OTJpcVBKM0lUWDBLb2NheU5keGl5SzUrVzYxb1YiXX0.eyJjb29sIjp0cnVlfQ.SIyJ7OuVyC8xn3d14SAn0sTFfp-1rPxQdO4CBbum_tgnT_eKjhTfTX0G5iSK0-s_ccyghZ_JRlDg4XZtxorMnpjIb3BaGs6sPcCS73Y_oRUkG9E50_8QqKRC6ASgA_CM
        """
    let validButNotCoolToken = """
        eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsIng1YyI6WyJNSUlCYXpDQjhnSUpBSmppU3ArRXhBalNNQWtHQnlxR1NNNDlCQUV3SXpFaE1COEdBMVVFQXd3WWFXNTBaWEp0WldScFlYUmxMbVY0WVcxd2JHVXVZMjl0TUNBWERUSXlNVEF6TURBeE1UWXhNVm9ZRHpRM05qQXdPVEkyTURFeE5qRXhXakFiTVJrd0Z3WURWUVFEREJCc1pXRm1MbVY0WVcxd2JHVXVZMjl0TUhZd0VBWUhLb1pJemowQ0FRWUZLNEVFQUNJRFlnQUV5aSs3dGJkSEVJTCtjUlNYOG5IZk80SVc5bFZ4bGlramVPTTNqNWhSaE94OGhna3lKa0pYQ0xPNzZMTEJacEhjYjQvaDlSY2xWRkh2cjBUQ3cwOXppb0lrclhFd0lRbk9MSXU1OVY0czJCRG5MRVVzYXU5a1lKQmNEeUdOcTRiSU1Ba0dCeXFHU000OUJBRURhUUF3WmdJeEFQK25xbXhYa3JPYXZCYkRsOTlsalhEWjVXZlVJY3hxSXF3L0NqakxnbmVZTmZoKzYzK0FxTi93cit2Z0h0WVRyd0l4QU5sc1p3WHQxRnpnZmE2TndSK2V3eE1lUnhVNjAxcmJ1QjZNaXJOY1dlUjNKT3pIN2V4REV2OVNiNnpiVi9sN1dRPT0iLCJNSUlCbFRDQ0FSeWdBd0lCQWdJSkFKTFRvWW1NOHpZK01Ba0dCeXFHU000OUJBRXdHekVaTUJjR0ExVUVBd3dRY205dmRDNWxlR0Z0Y0d4bExtTnZiVEFnRncweU1qRXdNekF3TVRFMU1qZGFHQTgwTnpZd01Ea3lOakF4TVRVeU4xb3dJekVoTUI4R0ExVUVBd3dZYVc1MFpYSnRaV1JwWVhSbExtVjRZVzF3YkdVdVkyOXRNSFl3RUFZSEtvWkl6ajBDQVFZRks0RUVBQ0lEWWdBRWtYQlkrU3JPQVNPV3R2TVUyOGVCQk9rdVd5R1BhbFExRVNlRXZqelNmTFR0TlhBdVZSNDJNNmFmdERVQjZFU2RZNE5MQ3JTelBNbUlLQ3Z5Y3lVbi8vZ1VJcmJlcGF2akVOMHBocWM3UEVtbmJNM0NnSWxSVmJIT3FpYTIxWXNhb3lNd0lUQVBCZ05WSFJNQkFmOEVCVEFEQVFIL01BNEdBMVVkRHdFQi93UUVBd0lDQkRBSkJnY3Foa2pPUFFRQkEyZ0FNR1VDTVFDbWxBN0ZxSmxmMEdSZnYzY1UxTUp0L2dlUWdKeVA0L2NEV1pGd3k5bnYvV1Z3cVYvdFY1N0VvSko1L0ZLYmZlY0NNQ2NLMDloKzJmcWhjYUFBVk1ORGhKMVFlcDFmaUZPR0o4U2pITjhVRDdqckJSTmZEUXFzKytZNXBvZ2xIa2hINmc9PSIsIk1JSUI2ekNDQVhHZ0F3SUJBZ0lKQUkzc2MvZjBrdEhUTUFvR0NDcUdTTTQ5QkFNQ01Cc3hHVEFYQmdOVkJBTU1FSEp2YjNRdVpYaGhiWEJzWlM1amIyMHdJQmNOTWpJeE1ETXdNREF6TkRRMFdoZ1BORGMyTURBNU1qWXdNRE0wTkRSYU1Cc3hHVEFYQmdOVkJBTU1FSEp2YjNRdVpYaGhiWEJzWlM1amIyMHdkakFRQmdjcWhrak9QUUlCQmdVcmdRUUFJZ05pQUFSL2huN3RNZEhiQi9hS0hqNmE2d0E4a21UbE5NT2RaeGlobHYvbnhHbTJBdndtY3d4WE4zVXU3Zm5lTk5waXNmRlo5SHdEQ3hRMEtOUnNjNjVmMjZKS0Yza0Y1L2hpTVE3RHdrL0Z1N2NoczNyVExNK1BwbEljVXBISlFlWDNoY2FqZnpCOU1BOEdBMVVkRXdFQi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZER0VqMjZvd1dnd2gwT2ZMN1grWG13bHcrTlRNRXNHQTFVZEl3UkVNRUtBRkRHRWoyNm93V2d3aDBPZkw3WCtYbXdsdytOVG9SK2tIVEFiTVJrd0Z3WURWUVFEREJCeWIyOTBMbVY0WVcxd2JHVXVZMjl0Z2drQWpleHo5L1NTMGRNd0NnWUlLb1pJemowRUF3SURhQUF3WlFJeEFQejhSOElidEJERjV5azJ2NXRadXBQQ242Tzd5SWY5dWpTVlR2KzUzUy9iKzZvdFpicHRVdWN6VkJnMVRwdUEzQUl3Q2RxTlVWQ0hNUld3M2hmRG9Oa1EwV053a3E3QlJ6ZlBLVjk5MmlxUEozSVRYMEtvY2F5TmR4aXlLNStXNjFvViJdfQ.eyJjb29sIjpmYWxzZX0.w33aCCe-NxYnkQ3zh4MxZh7Mn8tXqdP-HlD6MzclhdBLvt3yMb6BkJ66zlBmphVDHcPq9QB9PNFNvJq0c26imGRVrUQqfhJsjhTbD0TMZqzhZMJKs0wkb4YYCJQyBQz3
        """
}

/// Each token has the following payload:
///
///     {
///        "cool" : true
///     }
private struct TokenPayload: JWTPayload {
    var cool: Bool

    func verify(using signer: JWTSigner) throws {
        if !cool {
            throw JWTError.claimVerificationFailure(name: "cool", reason: "not cool")
        }
    }
}
