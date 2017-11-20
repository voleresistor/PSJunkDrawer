Configuration DFSServers{
    Node (""){
        # Install DFS Namspacing
        WindowsFeature DFSNameSpace{
            Ensure = "Present"
            Name = "FS-DFS-Namespace"
        }
    }
}