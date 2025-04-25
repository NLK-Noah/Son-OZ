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

    fun {Duration TotalSeconds Partition}
        Flattened = {PartitionToTimedList Partition}
        fun {TotalDuree L}
           case L
           of nil then 0.0
           [] H|T then
              case H
              of note(duration:D ...) then (D + {TotalDuree T})
              [] silence(duration:D) then (D + {TotalDuree T})
              [] _ then {TotalDuree T}
              end
           end
        end
        Prev = {TotalDuree Flattened}
        Factor = if Prev == 0.0 then 1.0 else (TotalSeconds / Prev) end
        
        fun {Scale L}
           case L
           of nil then nil
           [] H|T then
              case H
              of note(name:N octave:O sharp:S duration:D instrument:I) then
                 note(name:N octave:O sharp:S duration:(D * Factor) instrument:I) | {Scale T}
              [] silence(duration:D) then
                 silence(duration:(D * Factor)) | {Scale T}
              [] _ then H | {Scale T}
              end
           end
        end
     in
        {Scale Flattened}
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
     

     fun {NoteToIndex Name Sharp}
        case Name#Sharp
        of c#false then 0
        [] c#true  then 1
        [] d#false then 2
        [] d#true  then 3
        [] e#false then 4
        [] f#false then 5
        [] f#true  then 6
        [] g#false then 7
        [] g#true  then 8
        [] a#false then 9
        [] a#true  then 10
        [] b#false then 11
        else raise error(invalidNote(Name#Sharp)) end
        end
     end
     
     fun {IndexToNote Index}
        case (Index mod 12 + 12) mod 12
        of 0 then c#false
        [] 1 then c#true
        [] 2 then d#false
        [] 3 then d#true
        [] 4 then e#false
        [] 5 then f#false
        [] 6 then f#true
        [] 7 then g#false
        [] 8 then g#true
        [] 9 then a#false
        [] 10 then a#true
        [] 11 then b#false
        end
     end
     
     fun {TransposeNote Note Semitones}
        StartID = {NoteToIndex Note.name Note.sharp}
        NewID = StartID + Semitones
     
        CorrectedID = (NewID + 12) mod 12   % On ajoute 12 pour éviter négatif
        OctaveChange = (NewID div 12)
     
        % Cas spécial : si NewID < 0 et NewID mod 12 ≠ 0, il faut corriger encore l'octave
        NewOctave = if NewID < 0 andthen NewID mod 12 \= 0 then Note.octave + OctaveChange - 1
           else Note.octave + OctaveChange end
     
        NewName#NewSharp = {IndexToNote CorrectedID}
     in
        note(name:NewName octave:NewOctave sharp:NewSharp duration:Note.duration instrument:Note.instrument)
     end
        
     
     
     fun {Transpose Semitones Partition}
        case Partition
        of nil then nil
        [] H|T then
           if {IsList H} then
              % Cas où H est un accord (liste de notes)
              local
                 Extended = {Map H NoteToExtended}
                 Transposed = {Map Extended fun {$ N}
                    case N
                    of note(...) then
                       {TransposeNote N Semitones}
                    [] silence(duration:_) then
                       N
                    else
                       raise error(invalidElementInTranspose(N)) end
                    end
                 end}
              in
                 Transposed | {Transpose Semitones T}
              end
           else
              local
                 Extended = {NoteToExtended H}
              in
                 case Extended
                 of note(...) then
                    {TransposeNote Extended Semitones} | {Transpose Semitones T}
                 [] silence(duration:_) then
                    Extended | {Transpose Semitones T}
                 else
                    raise error(invalidElementInTranspose(Extended)) end
                 end
              end
           end
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
            elseif {IsRecord H} andthen {Label H} == duration then 
                {Append {Duration H.seconds H.partition} {PartitionToTimedList T}}                         
            elseif {IsRecord H} andthen {Label H} == drone then 
                {Append {Drone H.note H.amount} {PartitionToTimedList T}}             
            elseif {IsRecord H} andthen {Label H} == mute then 
                {Append {Mute H.amount} {PartitionToTimedList T}}    
            elseif {IsRecord H} andthen {Label H} == transpose then
                {Append {PartitionToTimedList {Transpose H.semitones H.partition}} {PartitionToTimedList T}}                      
            else 
                {NoteToExtended H} | {PartitionToTimedList T}
            end
        end
    end
end 