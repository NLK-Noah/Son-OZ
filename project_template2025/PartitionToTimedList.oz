functor
import
   Project2025
   System
   Property
   Browser
export 
   partitionToTimedList: PartitionToTimedList
define
    % Translate a note to the extended notation.
    fun {NoteToExtended Note}
        case Note
        of nil then nil 
        [] note(...) then Note
        [] silence(duration: _) then Note
        [] silence then silence(duration:1.0)
        [] Name#Octave then
            if {IsAtom Name} andthen {IsInt Octave} then
               note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
            else
               raise error(invalidNoteTuple(Note)) end
            end
        [] Atom then
            case {AtomToString Atom}
            of [_] then
                note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
            [] [N O] then
                note(name:{StringToAtom [N]}
                    octave:{StringToInt [O]}
                    sharp:false
                    duration:1.0
                    instrument: none)
            else
                raise error(invalidNoteAtom(Atom)) end
            end
           
        else
            raise error(invalidNoteFormat(Note)) end
        end
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fun {ChordToExtendedChord Chord}
        case Chord
        of nil then nil
    
        [] H|T then 
            if {IsAtom H} then 
                {NoteToExtended H} | {ChordToExtendedChord T}
            
            elseif {IsRecord H} andthen ({Label H} == note orelse {Label H} == silence) then
                H | {ChordToExtendedChord T}
            
            else
                {NoteToExtended H} | {ChordToExtendedChord T}
            end
    
        else
            raise error(invalidChord(Chord)) end
        end
    end

    fun {Stretch Factor Partition}
        case Partition
        of nil then nil
        [] H|T then
           case {NoteToExtended H}
           of note(name:N octave:O sharp:S duration:D instrument:I) then
              note(name:N
                   octave:O
                   sharp:S
                   duration:D * Factor
                   instrument:I)
              | {Stretch Factor T}
           [] silence(duration:D) then
              silence(duration:D * Factor) | {Stretch Factor T}
           else
            {Stretch Factor T}
           end
        end
    end       

    fun {Drone NoteOrChord Amount}
        if Amount =< 0 then 
           nil
        elseif {IsList NoteOrChord} andthen {IsList {List.nth NoteOrChord 1}} then
           % Cas: c’est une liste de listes => accord (chord)
           {ChordToExtendedChord {List.nth NoteOrChord 1}} | {Drone NoteOrChord (Amount - 1)}
        else
           % Cas: c’est une liste de notes => notes simples
           {Append {Map NoteOrChord NoteToExtended} {Drone NoteOrChord (Amount - 1)}}
        end
    end 

     fun {Mute Amount}
        if Amount =< 0 then nil
        else
           silence(duration:1.0) | {Mute (Amount - 1)}
        end
     end
     
     
   fun {PartitionToTimedList Partition}
        case Partition of nil then nil
        [] H|T then
            if {IsAtom H} then 
                {NoteToExtended H} | {PartitionToTimedList T}
            elseif {IsRecord H} andthen {Label H} == note then
                H | {PartitionToTimedList T}
            elseif {IsRecord H} andthen {Label H} == silence then
                H | {PartitionToTimedList T}
            elseif {IsRecord H} andthen {Label H} == '|' then 
                local Chord = {ChordToExtendedChord H} in
                    if Chord == nil then Chord
                    else
                        Chord | {PartitionToTimedList T}
                    end
                end
            elseif {IsRecord H} andthen {Label H} == stretch then 
                {Append {PartitionToTimedList {Stretch H.factor H.partition}} {PartitionToTimedList T}}            
            elseif {IsRecord H} andthen {Label H} == drone then 
                {Append {Drone H.note H.amount} {PartitionToTimedList T}}             
            elseif {IsRecord H} andthen {Label H} == mute then 
                {Append {Mute H.amount} {PartitionToTimedList T}}             
            else 
                {NoteToExtended H} | {PartitionToTimedList T}
            end
        end
    end
end 