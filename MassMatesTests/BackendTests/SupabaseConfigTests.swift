import Foundation
import Testing
@testable import MassMates

struct SupabaseConfigTests {
    @Test("SupabaseConfig.load reads the URL and the publishable key from the bundle info dictionary")
    func loadsFromBundleInfoDictionary() throws {
        let config = try SupabaseConfig.load()
        #expect(config.apiBaseURL.absoluteString == "https://khovpljkitslmjmonuzu.supabase.co")
        #expect(config.publishableKey == "sb_publishable_K-dwtbcBgNqSAEJX4G8tVg_j_ozahqI")
    }

    @Test("SupabaseConfig.load builds the Realtime websocket URL with the apikey and the protocol version")
    func buildsRealtimeURL() throws {
        let config = try SupabaseConfig.load()
        #expect(config.realtimeURL.scheme == "wss")
        #expect(config.realtimeURL.path == "/realtime/v1/websocket")
        #expect(config.realtimeURL.absoluteString.contains("apikey=\(config.publishableKey)"))
        #expect(config.realtimeURL.absoluteString.contains("vsn=1.0.0"))
    }

    @Test("SupabaseConfig.load throws configurationMissing when a key is absent")
    func throwsWhenAKeyIsMissing() {
        #expect(throws: BackendError.configurationMissing(key: "SUPABASE_URL")) {
            try SupabaseConfig.load(infoDictionary: [:])
        }
        #expect(throws: BackendError.configurationMissing(key: "SUPABASE_PUBLISHABLE_KEY")) {
            try SupabaseConfig.load(infoDictionary: ["SUPABASE_URL": "https://example.supabase.co"])
        }
        #expect(throws: BackendError.configurationMissing(key: "SUPABASE_URL")) {
            try SupabaseConfig.load(infoDictionary: ["SUPABASE_PUBLISHABLE_KEY": "sb_publishable_x"])
        }
    }

    @Test("The publishable key never leaks a service-role secret")
    func usesOnlyThePublishableKey() throws {
        let config = try SupabaseConfig.load()
        #expect(!config.publishableKey.contains("service_role"))
        #expect(config.publishableKey.hasPrefix("sb_publishable_"))
    }
}
