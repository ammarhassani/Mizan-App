//
//  NetworkClient.swift
//  Mizan
//
//  URLSession wrapper with retry logic and error handling
//

import Foundation
import os.log

final class NetworkClient {
    private let session: URLSession
    private let config: APIConfig

    init() {
        self.config = ConfigurationManager.shared.prayerConfig.api

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(config.timeoutSeconds)
        configuration.timeoutIntervalForResource = TimeInterval(config.timeoutSeconds * 2)
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpMaximumConnectionsPerHost = 4

        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Request Methods

    /// Perform a network request with automatic retry logic
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type = T.self
    ) async throws -> T {
        var lastError: APIError?

        // Retry logic with exponential backoff
        for attempt in 0..<config.retryAttempts {
            do {
                let data = try await performRequest(endpoint)
                return try decodeResponse(data, as: T.self)

            } catch let error as APIError {
                lastError = error
                MizanLogger.shared.network.warning("Request attempt \(attempt + 1)/\(self.config.retryAttempts) failed: \(error.localizedDescription)")

                // Don't retry on certain errors
                switch error {
                case .invalidURL, .invalidResponse, .decodingError:
                    throw error
                case .httpError(let statusCode):
                    // Don't retry 4xx client errors (except 429 rate limit)
                    if (400...499).contains(statusCode) && statusCode != 429 {
                        throw error
                    }
                case .networkError, .timeout, .maxRetriesExceeded:
                    break // Retry these
                }

                // Wait before retrying (exponential backoff)
                if attempt < config.retryAttempts - 1 {
                    let delay = config.retryDelaySeconds[attempt]
                    try await _Concurrency.Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
                }

            } catch {
                lastError = .networkError(error)
                MizanLogger.shared.network.error("Unexpected error: \(error.localizedDescription)")
            }
        }

        // All attempts failed
        throw lastError ?? .maxRetriesExceeded
    }

    // MARK: - Private Methods

    private func performRequest(_ endpoint: APIEndpoint) async throws -> Data {
        let request = try endpoint.urlRequest()

        MizanLogger.shared.network.debug("Request: \(request.url?.absoluteString ?? "unknown")")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        MizanLogger.shared.network.debug("Response status: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        return data
    }

    private func decodeResponse<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            MizanLogger.shared.network.error("Decoding error: \(error.localizedDescription)")
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case timeout
    case decodingError(Error)
    case maxRetriesExceeded

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .networkError, .timeout:
            return true
        case .httpError(let code):
            // Retry on server errors (5xx) and rate limiting (429)
            return code >= 500 || code == 429
        case .maxRetriesExceeded:
            return false
        case .invalidURL, .invalidResponse, .decodingError:
            return false
        }
    }
}
