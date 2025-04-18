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
         note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
      [] Atom then
         case {AtomToString Atom}
         of [_] then
            note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
         [] [N O] then
            note(name:{StringToAtom [N]}
                 octave:{StringToInt [O]}
                 sharp:false
                 duration:1.0
                 instrument:none)
         [] [N '#' O] then
                    note(name:{StringToAtom [N]}
                         octave:{StringToInt [O]}
                         sharp:true
                         duration:1.0
                         instrument:none)
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {ChordToExtendedChord Chord}
      case Chord of
         nil then nil 
      [] H|T then 
            if {IsAtom H} then 
               [{NoteToExtended H}] | {ChordToExtendedChord T}
            elseif {IsRecord H} andthen ({Label H} == note orelse {Label H} == silence) then
               H | {ChordToExtendedChord T}
            else 
                {ChordToExtendedChord T}
            end
      end
   end

   fun {PartitionToTimedList Partition}
      case Partition of
         nil then
            nil
      [] H|T then
            if {IsAtom H} then 
               {NoteToExtended H} | {PartitionToTimedList T}
   
            elseif {IsRecord H} andthen {Label H} == note then 
               H | {PartitionToTimedList T}
   
            elseif {IsRecord H} andthen {Label H} == silence then 
               H | {PartitionToTimedList T}
   
            elseif {IsRecord H} andthen {Label H} == '|' then 
                local ExtendedChord = {ChordToExtendedChord H}
                in
                    if ExtendedChord == nil then 
                        {PartitionToTimedList T}
                    else 
                        [ExtendedChord] | {PartitionToTimedList T}
                    end
                end
            else 
                {NoteToExtended H} | {PartitionToTimedList T}
            end
      end
   end 

end
