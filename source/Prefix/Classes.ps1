enum Scope {
    ParentScope
    ChildScope
}

enum NotSaved {
    RunFromDisk
    RunFromTemp
}

enum Untitled {
    Ignore
    SaveAsTemp
}

class ISEPesterConfiguration {
    [Scope]$InvokeScope
    [NotSaved]$ActionNotSaved
    [Untitled]$ActionUntitled

    ISEPesterConfiguration () {
        $this.InvokeScope = [Scope]::ParentScope
        $this.ActionNotSaved = [NotSaved]::RunFromDisk
        $this.ActionUntitled = [Untitled]::Ignore
    }

    [ISEPesterConfiguration] Clone () {
        return [ISEPesterConfiguration]@{
            InvokeScope = $this.InvokeScope
            ActionNotSaved = $this.ActionNotSaved
            ActionUntitled = $this.ActionUntitled
        }
    }
}
