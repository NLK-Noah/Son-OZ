%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Projet Son'OZ - LINFO1104 (UCLouvain)
%%
%% Auteurs :
%%   - Kaan [0910-23-00]
%%   - Noah [8231-23-00]
%%
%% Fichier : PartitionToTimedList.oz
%% Description : Transformation de partitions musicales vers le format étendu.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
functor
import
   Project2025
   System
   Property
   Browser
export 
   partitionToTimedList: PartitionToTimedList
define
    % Convertit différents formats de note (atome, tuple, record) en note étendue.
    % Si l'entrée est un silence sans durée, elle reçoit une durée par défaut.
    % Si l'entrée est un atome 'a', une chaîne comme 'a4' ou un tuple comme 'a#4', elle est transformée en note complète.
    % Si l'entrée est déjà une note étendue, elle est laissée telle quelle.
    % Si l'entrée est un silence avec une durée, elle est laissée telle quelle.

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
    % Convertit une liste représentant un accord (mélange d'atomes, tuples ou notes) en une liste de notes étendues.
    % Ignore les silences déjà bien formés.

    fun {ChordToExtended Chord}
        case Chord
        of nil then nil
    
        [] H|T then 
            if {IsAtom H} then 
                {NoteToExtended H} | {ChordToExtended T}
            
            elseif {IsRecord H} andthen ({Label H} == note orelse {Label H} == silence) then
                H | {ChordToExtended T}
            
            else
                {NoteToExtended H} | {ChordToExtended T}
            end
    
        else
            raise error(invalidChord(Chord)) end
        end
    end

    % Applique une transformation de durée sur une partition.
    % La partition est d'abord convertie en format étendu.
    % La durée totale est calculée en sommant les durées des notes et silences.
    % On calcule la durée totale actuelle de la partition, puis on applique un facteur de mise à l'échelle
    % pour obtenir exactement Seconds de durée finale. Les silences et notes sont multipliés.
    % Les éléments non reconnus sont ignorés sans provoquer d'erreur.
    % La durée est exprimée en secondes.

    fun {Duration Seconds Partition}
        Flattened = {PartitionToTimedList Partition}
        fun {DurationAux L}
           case L
           of nil then 0.0
           [] H|T then
              case H
              of note(duration:D ...) then (D + {DurationAux T})
              [] silence(duration:D) then (D + {DurationAux T})
              [] _ then {DurationAux T}
              end
           end
        end
        Previous = {DurationAux Flattened}
        Factor = if Previous == 0.0 then 1.0 else (Seconds / Previous) end
        
        % Applique un facteur d'échelle sur chaque durée dans la partition
        fun {NewDuration L}
           case L
           of nil then nil
           [] H|T then
              case H
              of note(name:N octave:O sharp:S duration:D instrument:I) then 
               note(name:N octave:O sharp:S duration:(D * Factor) instrument:I) | {NewDuration T}
              [] silence(duration:D) then silence(duration:(D * Factor)) | {NewDuration T}
              [] _ then H | {NewDuration T}
              end
           end
        end
     in
        {NewDuration Flattened}
     end
    
    % Multiplie toutes les durées des éléments d'une partition par un facteur donné.
    % La partition est transformée note par note via NoteToExtended, puis chaque durée est étirée.
    % Les éléments non reconnus sont ignorés sans provoquer d'erreur.

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
                   instrument:I) | {Stretch Factor T}
           [] silence(duration:D) then
              silence(duration:D * Factor) | {Stretch Factor T}
           else
            {Stretch Factor T} % Ignore tout élément qui ne peut être étendu proprement
           end
        end
    end       

    % Crée une séquence répétitive de notes ou d'accords.
    % Répète 'Amount' fois une note ou un accord donné.
    % Si l'entrée est un accord (liste de listes), utilise ChordToExtended pour l'étendre.
    % Sinon, traite l'entrée comme une liste de notes simples et les étend via NoteToExtended.

    fun {Drone NoteOrChord Amount}
        if Amount =< 0 then 
           nil
        elseif {IsList NoteOrChord} andthen {IsList {List.nth NoteOrChord 1}} then
           % Une liste de listes => accord
           {ChordToExtended {List.nth NoteOrChord 1}} | {Drone NoteOrChord (Amount - 1)}
        else
           % Une liste de notes => notes simples
           {Append {Map NoteOrChord NoteToExtended} {Drone NoteOrChord (Amount - 1)}}
        end
    end 


    % Génère une liste contenant 'Amount' silences d'une durée de 1.0 chacun.
    % Utilisé pour insérer des passages silencieux dans une partition.
    % Si Amount est nul ou négatif, retourne une liste vide.

    fun {Mute Amount}
      if Amount =< 0 then nil
      else
         silence(duration:1.0) | {Mute (Amount - 1)}
      end
    end
     
     % Associe à chaque note (nom + altération) un index chromatique entre 0 et 11.
     % Utile pour effectuer des opérations comme la transposition.
     % Si la note n'est pas reconnue, lève une erreur explicite.

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

     % Convertit un index chromatique (0 à 11) en une note (nom + altération).
     % Utilisé lors de la transposition pour retrouver le nom correct d'une note après déplacement.
     % L'index est normalisé pour rester entre 0 et 11 même si négatif (on additionne alors avec un multiple de 12).

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

     % Transpose une seule note d'un nombre de demi-tons donné.
     % Gère correctement les cas de dépassement d'octave, vers le haut ou le bas.
     % Utilise NoteToIndex pour retrouver l'index initial et IndexToNote pour recoder la note transposée.

     fun {TransposeAux Note Semitones}
        FirstIndex = {NoteToIndex Note.name Note.sharp}
        NewIndex = FirstIndex + Semitones
        OptimisedIndex = (NewIndex + 12) mod 12   % On ajoute 12 pour éviter négatif
        OctaveChanged = (NewIndex div 12)
     
        % Cas spécial pour gérer correctement les négatifs
        NewPosOctave = if NewIndex < 0 andthen (NewIndex mod 12) \= 0 then (Note.octave + OctaveChanged - 1) 
        else Note.octave + OctaveChanged end
     
        NewName#NewSharp = {IndexToNote OptimisedIndex}
     in
        note(name:NewName octave:NewPosOctave sharp:NewSharp duration:Note.duration instrument:Note.instrument)
     end
        
     % Transpose une partition complète (notes et accords) d'un nombre de demi-tons donné.
     % Étend chaque note si nécessaire, puis applique TransposeNote pour ajuster le pitch.
     % Les silences sont laissés intacts. Les accords (listes) sont traités récursivement.

     fun {Transpose Semitones Partition}
        case Partition
        of nil then nil
        [] H|T then
           if {IsList H} then
              % Cas: H est un accord.
              local ExtendedNote = {Map H NoteToExtended} TransposedNote = {Map ExtendedNote fun {$ N}
                    case N
                    of note(...) then {TransposeAux N Semitones}
                    [] silence(duration:_) then N
                    else
                       raise error(invalidElementInTranspose(N)) end
                    end
                 end}
              in
                 TransposedNote | {Transpose Semitones T}
              end

           else
              local ExtendedNote = {NoteToExtended H} in
                 case ExtendedNote
                 of note(...) then {TransposeAux ExtendedNote Semitones} | {Transpose Semitones T}
                 [] silence(duration:_) then ExtendedNote | {Transpose Semitones T}
                 else
                    raise error(invalidElementInTranspose(ExtendedNote)) end
                 end
              end
           end
        end
     end
     




   % Fonction principale qui transforme une partition musicale en une liste de notes étendues normalisées.
   % Gère les cas suivants :
   %  - atomes simples (comme 'a') convertis via NoteToExtended
   %  - notes et silences déjà au bon format laissés tels quels
   %  - accords : convertis via ChordToExtended
   %  - transformations (stretch, duration, drone, mute, transpose) : appliquées récursivement

   fun {PartitionToTimedList Partition}
        case Partition of nil then nil
        [] H|T then
            if {IsAtom H} then {NoteToExtended H} | {PartitionToTimedList T}
            elseif {IsRecord H} andthen {Label H} == note then H | {PartitionToTimedList T}
            elseif {IsRecord H} andthen {Label H} == silence then H | {PartitionToTimedList T}
            elseif {IsRecord H} andthen {Label H} == '|' then 
                local Chord = {ChordToExtended H} in
                  if Chord == nil then Chord
                  else
                     Chord | {PartitionToTimedList T}
                  end
                end
            elseif {IsRecord H} andthen {Label H} == stretch then
               local SubPartition
                     Factor = H.factor
               in
                  % Supporte à la fois stretch(factor:... [notes]) et stretch(factor:... partition:...)
                  if {HasFeature H partition} then
                     SubPartition = H.partition
                  else
                     SubPartition = H.1
                  end
                  {Append {Stretch Factor {PartitionToTimedList SubPartition}} {PartitionToTimedList T}}
               end               
            elseif {IsRecord H} andthen {Label H} == duration then 
               local SubPartition
                     Seconds = H.seconds
               in
                  if {HasFeature H partition} then
                     SubPartition = H.partition
                  else
                     SubPartition = H.1
                  end
                  {Append {Duration Seconds SubPartition} {PartitionToTimedList T}}                         
               end
                                        
            elseif {IsRecord H} andthen {Label H} == drone then 
               local Notes Amount
               in
                  Notes  = if {HasFeature H note} then H.note else H.1 end
                  Amount = if {HasFeature H amount} then H.amount else H.2 end
                  {Append {Drone Notes Amount} {PartitionToTimedList T}}             
               end

            elseif {IsRecord H} andthen {Label H} == mute then 
               local Amount = if {HasFeature H amount} then H.amount else H.1 end
               in
                  {Append {Mute Amount} {PartitionToTimedList T}}    
               end
            
            elseif {IsRecord H} andthen {Label H} == transpose then
               local Semitones SubPartition
               in
                  Semitones = if {HasFeature H semitones} then H.semitones else H.1 end
                  SubPartition = if {HasFeature H partition} then H.partition else H.2 end
                  {Append {PartitionToTimedList {Transpose Semitones SubPartition}} {PartitionToTimedList T}}                      
               end
                                  
            else 
                {NoteToExtended H} | {PartitionToTimedList T}
            end
        end
    end
end 