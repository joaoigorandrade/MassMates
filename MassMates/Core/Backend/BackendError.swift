import Foundation

enum BackendError: Error, Sendable, Equatable {
    case configurationMissing(key: String)
    case invalidURL(String)
    case transport(String)
    case http(statusCode: Int, code: String?, message: String?)
    case rpc(statusCode: Int, key: String)
    case emailNotConfirmed
    case invalidCredentials
    case otpExpired
    case userAlreadyExists
    case unauthorized
    case forbidden
    case notFound
    case conflict(String)
    case rateLimited
    case server(String)
    case decoding(String)
    case keychain(Int32)
    case sessionMissing
    case realtime(String)

    var userMessage: String {
        switch self {
        case .configurationMissing(let key):
            "Configuração do servidor ausente (\(key))."
        case .invalidURL:
            "Endereço do servidor inválido."
        case .transport:
            "Não foi possível falar com o servidor. Verifique sua conexão."
        case .http(let statusCode, _, _):
            "O servidor respondeu com erro (\(statusCode))."
        case .rpc(let statusCode, _):
            "O servidor recusou a operação (\(statusCode))."
        case .emailNotConfirmed:
            "Confirme seu e-mail para continuar."
        case .invalidCredentials:
            "E-mail ou senha inválidos."
        case .otpExpired:
            "O código expirou. Peça um novo."
        case .userAlreadyExists:
            "Já existe uma conta com este e-mail."
        case .unauthorized:
            "Sua sessão expirou. Entre novamente."
        case .forbidden:
            "Você não tem permissão para esta ação."
        case .notFound:
            "Conteúdo não encontrado."
        case .conflict(let reason):
            reason
        case .rateLimited:
            "Muitas tentativas. Aguarde um instante."
        case .server:
            "O servidor está indisponível. Tente novamente."
        case .decoding:
            "Resposta inesperada do servidor."
        case .keychain:
            "Não foi possível guardar sua sessão com segurança."
        case .sessionMissing:
            "Você precisa entrar na sua conta."
        case .realtime:
            "Conexão em tempo real indisponível."
        }
    }
}
