 
 functor
 import
    Project2025
    System
    Property
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
        [] Name#Octave then note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
        [] Atom then
            case {AtomToString Atom}
            of [_] then
                % Conversion: a --> a4
                note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
            [] [N O] then
                % Conversion: a0 --> a octave 0
                note(name:{StringToAtom [N]}
                    octave:{StringToInt [O]}
                    sharp:false
                    duration:1.0
                    instrument: none)
            [] [N # O] then
                % Conversion: c#2 --> c octave 2 sharp:true
                note(name:{StringToAtom [N]}
                    octave:{StringToInt [O]}
                    sharp:true
                    duration:1.0
                    instrument: none)
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    fun {ChordToExtended Chord}
        {Map Chord NoteToExtended}
    end
    
    fun {IsExtendedChord C}
        fun {Check L}
           case L
           of nil then true
           [] note(...)|Rest then {Check Rest}
           [] silence(duration:_)|Rest then {Check Rest}
           else false
           end
        end
     in
        {Check C}
     end
     

     fun {PartitionToTimedList Partition}
        case Partition
        of nil then nil
        [] Item|Rest then
           FlatItem =
              if {IsList Item} andthen {IsExtendedChord Item} then
                 [Item]  % Accord étendu --> pas de conversion
              elseif {IsList Item} then
                 [{ChordToExtended Item}]  % Accord non étendu --> converti en étendu
              else
                 [{NoteToExtended Item}]   % Note simple --> converti en étendu
              end
           FlatRest = {PartitionToTimedList Rest}
        in
           {Append FlatItem FlatRest}
        end
     end
     
end