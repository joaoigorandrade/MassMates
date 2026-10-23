import Foundation

extension CommunitySampleData {
    static func initialMembers(for groupId: String) -> [GroupMemberSummary] {
        let isAdmin = CommunitySampleData.isCurrentUserAdmin(groupId: groupId)
        return [
            GroupMemberSummary(id: "\(groupId)-mem-leader", name: "Pe. Lucas Mendes", initials: "LM", roleLabel: "Líder", isCurrentUser: false),
            GroupMemberSummary(id: "\(groupId)-mem-you", name: "Você", initials: "VC", roleLabel: isAdmin ? "Líder" : "Membro", isCurrentUser: true),
            GroupMemberSummary(id: "\(groupId)-mem-mariana", name: "Mariana Silva", initials: "MS", roleLabel: "Membro", isCurrentUser: false),
            GroupMemberSummary(id: "\(groupId)-mem-gabriel", name: "Gabriel Prado", initials: "GP", roleLabel: "Membro", isCurrentUser: false),
            GroupMemberSummary(id: "\(groupId)-mem-cecilia", name: "Irmã Cecília", initials: "IC", roleLabel: "Membro", isCurrentUser: false),
            GroupMemberSummary(id: "\(groupId)-mem-teresa", name: "Dona Teresa", initials: "DT", roleLabel: "Membro", isCurrentUser: false),
            GroupMemberSummary(id: "\(groupId)-mem-carlos", name: "Dr. Carlos", initials: "DC", roleLabel: "Membro", isCurrentUser: false),
            GroupMemberSummary(id: "\(groupId)-mem-tiago", name: "Tiago", initials: "TR", roleLabel: "Membro", isCurrentUser: false),
            GroupMemberSummary(id: "\(groupId)-mem-beatriz", name: "Beatriz Lima", initials: "BL", roleLabel: "Membro", isCurrentUser: false),
            GroupMemberSummary(id: "\(groupId)-mem-mateus", name: "Mateus Almeida", initials: "MA", roleLabel: "Membro", isCurrentUser: false),
            GroupMemberSummary(id: "\(groupId)-mem-helena", name: "Helena Costa", initials: "HC", roleLabel: "Membro", isCurrentUser: false),
            GroupMemberSummary(id: "\(groupId)-mem-rafael", name: "Rafael Oliveira", initials: "RO", roleLabel: "Membro", isCurrentUser: false)
        ]
    }
}
