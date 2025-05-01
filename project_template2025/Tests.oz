functor
import
   Project2025
   Mix
   System
   Property
export
   test: Test
define

   PassedTests = {Cell.new 0}
   TotalTests  = {Cell.new 0}

   FiveSamples = 0.00011337868 % Duration to have only five samples

   % Takes a list of samples, round them to 4 decimal places and multiply them by
   % 10000. Use this to compare list of samples to avoid floating-point rounding
   % errors.
   fun {Normalize Samples}
      {Map Samples fun {$ S} {IntToFloat {FloatToInt S*10000.0}} end}
   end

   proc {Assert Cond Msg}
      TotalTests := @TotalTests + 1
      if {Not Cond} then
         {System.show Msg}
      else
         PassedTests := @PassedTests + 1
      end
   end

   proc {AssertEquals A E Msg}
      TotalTests := @TotalTests + 1
      if A \= E then
         {System.show Msg}
         {System.show actual(A)}
         {System.show expect(E)}
      else
         PassedTests := @PassedTests + 1
      end
   end

   fun {NoteToExtended Note}
      case Note
      of note(...) then
         Note
      [] silence(duration: _) then
         Note
      [] _|_ then
         {Map Note NoteToExtended}
      [] nil then
         nil
      [] silence then
         silence(duration:1.0)
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
                 instrument: none)
         [] [N '#' O] then
                  note(name:{StringToAtom [N]}
                       octave:{StringToInt [O]}
                       sharp:true
                       duration:1.0
                       instrument:none)
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % TEST PartitionToTimedNotes

   proc {TestNotes P2T}
      P1 = [a0 b1 c#2 d#3 e silence]
      E1 = {Map P1 NoteToExtended}
   in
      {AssertEquals {P2T P1} E1 "TestNotes"}
   end

   proc {TestNotes_Sharp P2T}
      P = [g#3]
      E = [note(name:g octave:3 sharp:true duration:1.0 instrument:none)]
   in
      {AssertEquals {P2T P} E "TestNotes: sharp note"}
   end

   proc {TestNotes_Sharp2 P2T}
      P = [c#4 d#5 e6]
      E = {Map P NoteToExtended}
   in
      {AssertEquals {P2T P} E "TestNotes: notes with sharps and octaves"}
   end
   
   proc {TestNotes_SimpleAtom P2T}
      P = [e]
      E = [note(name:e octave:4 sharp:false duration:1.0 instrument:none)]
   in
      {AssertEquals {P2T P} E "TestNotes: simple atom"}
   end
   
   proc {TestNotes_SilenceAtom P2T}
      P = [silence]
      E = [silence(duration:1.0)]
   in
      {AssertEquals {P2T P} E "TestNotes: silence atom"}
   end   

   proc {TestChords P2T}
      P2 = [c4 d#2 g4]
      E2 = [
            note(name:c octave:4 sharp:false duration:1.0 instrument:none)
            note(name:d octave:2 sharp:true duration:1.0 instrument:none)
            note(name:g octave:4 sharp:false duration:1.0 instrument:none)
          ]
   in
      {AssertEquals {P2T [P2]} [E2] "TestChords: simple"}
   end

   proc {TestChords_Silence P2T}
      P = [[silence]]
      E = [[silence(duration:1.0)]]
   in
      {AssertEquals {P2T P} E "TestChords: chord with silence only"}
   end

   proc {TestChords_Random P2T}
      P = [c#4 d e#5]
      E = [
         note(name:c octave:4 sharp:true duration:1.0 instrument:none)
         note(name:d octave:4 sharp:false duration:1.0 instrument:none)
         note(name:e octave:5 sharp:true duration:1.0 instrument:none)
      ]
   in
      {AssertEquals {P2T [P]} [E] "TestChords: random sharp and natural"}
   end

   proc {TestIdentity P2T}
      P3 = [
         note(name:a octave:3 sharp:true duration:2.0 instrument:none)
         silence(duration:0.5)
         [
            note(name:c octave:4 sharp:false duration:1.0 instrument:none)
            note(name:e octave:4 sharp:false duration:1.0 instrument:none)
         ]
      ]
   in
      {AssertEquals {P2T P3} P3 "TestIdentity"}
   end

   proc {TestIdentity_Silence_Note P2T}
      P = [
         silence(duration:0.25)
         note(name:b octave:2 sharp:true duration:0.75 instrument:none)
      ]
   in
      {AssertEquals {P2T P} P "TestIdentity: silence first"}
   end

   proc {TestIdentity_Mixed P2T}
      P = [
         note(name:c octave:4 sharp:false duration:1.0 instrument:none)
         silence(duration:1.0)
         [
            note(name:e octave:4 sharp:true duration:2.0 instrument:none)
         ]
      ]
   in
      {AssertEquals {P2T P} P "TestIdentity: mixed elements already extended"}
   end   
   
   proc {TestDuration P2T}
      P = [duration(seconds:2.0 partition:[a b])]
      E = [
         note(name:a octave:4 sharp:false duration:1.0 instrument:none)
         note(name:b octave:4 sharp:false duration:1.0 instrument:none)
      ]
   in
      {AssertEquals {P2T P} E "TestDuration: simple case"}
   end

   proc {TestDurationSilence P2T}
      P = [duration(seconds:3.0 partition:[a silence b])]
      E = [
         note(name:a octave:4 sharp:false duration:1.0 instrument:none)
         silence(duration:1.0)
         note(name:b octave:4 sharp:false duration:1.0 instrument:none)
      ]
   in
      {AssertEquals {P2T P} E "TestDuration: with silence"}
   end

   proc {TestDurationAdd P2T}
      P = [duration(seconds:4.0 partition:[a b])]
      E = [
         note(name:a octave:4 sharp:false duration:2.0 instrument:none)
         note(name:b octave:4 sharp:false duration:2.0 instrument:none)
      ]
   in
      {AssertEquals {P2T P} E "TestDuration: up to 4.0s"}
   end
   
   proc {TestDurationSub P2T}
      P = [duration(seconds:1.0 partition:[a b])]
      E = [
         note(name:a octave:4 sharp:false duration:0.5 instrument:none)
         note(name:b octave:4 sharp:false duration:0.5 instrument:none)
      ]
   in
      {AssertEquals {P2T P} E "TestDuration: down to 1.0s"}
   end

   proc {TestDurationExact P2T}
      P = [duration(seconds:2.0 partition:[
         note(name:c octave:4 sharp:false duration:1.0 instrument:none)
         note(name:d octave:4 sharp:false duration:1.0 instrument:none)
      ])]
      E = [
         note(name:c octave:4 sharp:false duration:1.0 instrument:none)
         note(name:d octave:4 sharp:false duration:1.0 instrument:none)
      ]
   in
      {AssertEquals {P2T P} E "TestDuration: already matching total duration"}
   end

   proc {TestDurationEmpty P2T}
      P = [duration(seconds:3.0 partition:nil)]
      E = nil
   in
      {AssertEquals {P2T P} E "TestDuration: empty partition returns nil"}
   end
   
   proc {TestStretch P2T}
      P5 = [stretch(factor:2.0 partition:[a b silence])]
      E5 = [
         note(name:a octave:4 sharp:false duration:2.0 instrument:none)
         note(name:b octave:4 sharp:false duration:2.0 instrument:none)
         silence(duration:2.0)
      ]
   in
      {AssertEquals {P2T P5} E5 "TestStretch: notes + silence étirés"}
   end 
   
   proc {TestStretch_Silence P2T}
      P = [stretch(factor:3.0 partition:[silence])]
      E = [silence(duration:3.0)]
   in
      {AssertEquals {P2T P} E "TestStretch: silence stretched"}
   end

   proc {TestStretch_EmptyPartition P2T}
      P = [stretch(factor:2.0 partition:nil)]
      E = nil
   in
      {AssertEquals {P2T P} E "TestStretch: empty partition"}
   end   

   proc {TestStretch_SingleNote P2T}
      P = [stretch(factor:3.0 partition:[d])]
      E = [note(name:d octave:4 sharp:false duration:3.0 instrument:none)]
   in
      {AssertEquals {P2T P} E "TestStretch: single note stretched"}
   end   

   proc {TestDrone_SingleNote P2T}
   P = [drone(note:[a] amount:3)]
   E = [
      note(name:a octave:4 sharp:false duration:1.0 instrument:none)
      note(name:a octave:4 sharp:false duration:1.0 instrument:none)
      note(name:a octave:4 sharp:false duration:1.0 instrument:none)
   ]
   in
      {AssertEquals {P2T P} E "TestDrone: single note repeated 3 times"}
   end

   proc {TestDrone_NoteList P2T}
      P = [drone(note:[c e] amount:2)]
      E = [
         note(name:c octave:4 sharp:false duration:1.0 instrument:none)
         note(name:e octave:4 sharp:false duration:1.0 instrument:none)
         note(name:c octave:4 sharp:false duration:1.0 instrument:none)
         note(name:e octave:4 sharp:false duration:1.0 instrument:none)
      ]
   in
      {AssertEquals {P2T P} E "TestDrone: note list repeated"}
   end

   proc {TestDrone_Chord P2T}
      P = [drone(note:[[c e]] amount:2)]
      E = [
         [note(name:c octave:4 sharp:false duration:1.0 instrument:none)
          note(name:e octave:4 sharp:false duration:1.0 instrument:none)]
         [note(name:c octave:4 sharp:false duration:1.0 instrument:none)
          note(name:e octave:4 sharp:false duration:1.0 instrument:none)]
      ]
   in
      {AssertEquals {P2T P} E "TestDrone: chord repeated 2 times"}
   end
   
   proc {TestMute P2T}
      P7 = [mute(amount:3)]
      E7 = [
         silence(duration:1.0)
         silence(duration:1.0)
         silence(duration:1.0)
      ]
   in
      {AssertEquals {P2T P7} E7 "TestMute: silence répété 3 fois"}
   end

   proc {TestMute_Single P2T}
      P = [mute(amount:1)]
      E = [silence(duration:1.0)]
   in
      {AssertEquals {P2T P} E "TestMute: single silence"}
   end

   proc {TestMute_Zero P2T}
      P = [mute(amount:0)]
      E = nil
   in
      {AssertEquals {P2T P} E "TestMute: zero silence"}
   end   

   proc {TestTranspose_SimpleNote P2T}
      P = [transpose(semitones:1 partition:[c])]
      E = [
         note(name:c sharp:true octave:4 duration:1.0 instrument:none)
      ]
   in
      {AssertEquals {P2T P} E "TestTranspose: simple note up by 1 semitone"}
   end

   proc {TestTranspose_SimpleNoteDown P2T}
      P = [transpose(semitones:~1 partition:[c])]
      E = [
         note(name:b octave:3 sharp:false duration:1.0 instrument:none)
      ]
   in
      {AssertEquals {P2T P} E "TestTranspose: simple note down by 1 semitone"}
   end

   proc {TestTranspose_SeveralNotes P2T}
      P = [transpose(semitones:2 partition:[c d e])]
      E = [
         note(name:d octave:4 sharp:false duration:1.0 instrument:none)
         note(name:e octave:4 sharp:false duration:1.0 instrument:none)
         note(name:f sharp:true octave:4 duration:1.0 instrument:none)
      ]
   in
      {AssertEquals {P2T P} E "TestTranspose: several notes up by 2 semitones"}
   end

   proc {TestTranspose_NegativeOverBoundary P2T}
      P = [transpose(semitones:~3 partition:[c])]
      E = [
         note(name:a octave:3 sharp:false duration:1.0 instrument:none)
      ]
   in
      {AssertEquals {P2T P} E "TestTranspose: note down crossing octave boundary"}
   end

   proc {TestTranspose_WithChord P2T}
      P = [transpose(semitones:1 partition:[[c e g]])]
      E = [
         [
            note(name:c sharp:true octave:4 duration:1.0 instrument:none)
            note(name:f octave:4 sharp:false duration:1.0 instrument:none)
            note(name:g sharp:true octave:4 duration:1.0 instrument:none)
         ]
      ]
   in
      {AssertEquals {P2T P} E "TestTranspose: chord up by 1 semitone"}
   end

   proc {TestTranspose_Empty P2T}
      P = [transpose(semitones:4 partition:nil)]
      E = nil
   in
      {AssertEquals {P2T P} E "TestTranspose: empty partition"}
   end

   proc {TestP2TChaining P2T}
      P = [
         a
         [b c]
         stretch(factor:2.0 partition:[d])
         drone(note:[e] amount:2)
         mute(amount:1)
      ]
      E = {Append
            [note(name:a octave:4 sharp:false duration:1.0 instrument:none)]
            {Append
               [[note(name:b octave:4 sharp:false duration:1.0 instrument:none)
                 note(name:c octave:4 sharp:false duration:1.0 instrument:none)]]
               {Append
                  [note(name:d octave:4 sharp:false duration:2.0 instrument:none)]
                  {Append
                     [note(name:e octave:4 sharp:false duration:1.0 instrument:none)
                      note(name:e octave:4 sharp:false duration:1.0 instrument:none)]
                     [silence(duration:1.0)]}}}}
   in
      {AssertEquals {P2T P} E "TestP2TChaining: various transformations"}
   end    

   proc {TestEmptyChords P2T}
      P10 = [nil] 
      E10 = [nil]
   in
      {AssertEquals {P2T P10} E10 "TestEmptyChords"}
   end

   proc {TestEmptyChords_NestedNil P2T}
      P = [[nil]]
      E = [[nil]]
   in
      {AssertEquals {P2T P} E "TestEmptyChords: nested nil"}
   end   
      
   proc {TestP2T P2T}
      {TestNotes P2T}
      {TestNotes_Sharp P2T}
      {TestNotes_SimpleAtom P2T}
      {TestNotes_SilenceAtom P2T}
      {TestNotes_Sharp2 P2T}
      {TestChords_Random P2T}
      {TestChords P2T}
      {TestChords_Silence P2T}
      {TestIdentity P2T}
      {TestIdentity_Silence_Note P2T}
      {TestIdentity_Mixed P2T}
      {TestDuration P2T}
      {TestDurationSilence P2T}
      {TestDurationAdd P2T}
      {TestDurationSub P2T}
      {TestDurationExact P2T}
      {TestDurationEmpty P2T}
      {TestStretch P2T}
      {TestStretch_Silence P2T}
      {TestStretch_EmptyPartition P2T}
      {TestStretch_SingleNote P2T}
      {TestDrone_SingleNote P2T}
      {TestDrone_NoteList P2T}
      {TestDrone_Chord P2T}
      {TestMute P2T}
      {TestMute_Single P2T}
      {TestMute_Zero P2T}
      {TestTranspose_SimpleNote P2T}
      {TestTranspose_SimpleNoteDown P2T}
      {TestTranspose_SeveralNotes P2T}
      {TestTranspose_NegativeOverBoundary P2T}
      {TestTranspose_WithChord P2T}
      {TestTranspose_Empty P2T}
      {TestP2TChaining P2T}
      {TestEmptyChords P2T}  
      {TestEmptyChords_NestedNil P2T} 
      {AssertEquals {P2T nil} nil 'nil partition'}
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    TEST Mix

    proc {TestSamples P2T Mix}
      E1 = [0.1 ~0.2 0.3]
      M1 = [samples(E1)]
   in
      {AssertEquals {Mix P2T M1} E1 'TestSamples: simple'}
   end

   proc {TestPartition P2T Mix}
      Partition = [note(name:a octave:4 sharp:false duration:1.0 instrument:none)]
      Music = [partition(Partition)]
      Samples = {Mix P2T Music}
      ExpectedLength = 44100
   in
      {AssertEquals {Length Samples} ExpectedLength 'TestPartition: 1 note de 1.0s => 44100 samples'}
   end

   proc {TestPartition2 P2T Mix}
      % Une partition contenant juste la note a4 (1s par défaut)
      P = [note(name:a octave:4 sharp:false duration:1.0 instrument:none)]
      M = [partition(P)]
   
      % Résultat attendu : on applique Mix dessus
      Res = {Mix P2T M}
   
      % On ne compare pas la liste entière (trop longue),
      % mais on vérifie juste la longueur et les bornes
   
      L = {Length Res}
   
   in
      {AssertEquals L 44100 'TestPartition: longueur pour a4'}
   end
   
   proc {TestWave P2T Mix}
      W1 = wave(filename:"wave/animals/cow.wav")
      W2 = wave(filename:"wave/animals/duck_quack.wav")
      E1 = {Project2025.readFile "wave/animals/cow.wav"}
      E2 = {Project2025.readFile "wave/animals/duck_quack.wav"}
   in
      {AssertEquals {Mix P2T [samples(E1)]} E1 "TestWave: direct samples"}
      {AssertEquals {Mix P2T [W1]} E1 "TestWave: wave cow"}
      {AssertEquals {Mix P2T [W2]} E2 "TestWave: wave duck quack"}
   end

   proc {TestMerge P2T Mix}
      M1 = [samples([0.1 0.2 0.3])]
      M2 = [samples([0.4 0.1])]
      M3 = [samples([0.5])]
   
      In = [merge([0.5#M1 0.25#M2 0.25#M3])]
      Out = [0.3 0.125 0.125]
   in
      {AssertEquals {Mix P2T In} Out "TestMerge: mixing 3 musics avec les intensities"}
   end

   proc {TestMerge_Nil P2T Mix}
      M1 = [samples([0.1 0.2 0.3])]
      M2 = [samples([0.4 0.1])]
      M3 = [nil]
   
      In = [merge([0.5#M1 0.25#M2 0.25#M3])]
      Out = [0.3 0.125 0.0]
   in 
      {AssertEquals {Mix P2T In} Out "TestMerge: mixing 3 musics avec nil"}
   end

   proc {TestReverse P2T Mix}
      skip
   end

   proc {TestRepeat P2T Mix}
      skip
   end

   proc {TestLoop P2T Mix}
      skip
   end

   proc {TestClip P2T Mix}
      skip
   end

   proc {TestEcho P2T Mix}
      skip
   end

   proc {TestFade P2T Mix}
      skip
   end

   proc {TestCut P2T Mix}
      skip
   end

   proc {TestMix P2T Mix}
      {TestSamples P2T Mix}
      {TestPartition P2T Mix}
      {TestPartition2 P2T Mix}
      {TestWave P2T Mix}
      {TestMerge P2T Mix}
      {TestMerge_Nil P2T Mix}
      {TestRepeat P2T Mix}
      {TestLoop P2T Mix}
      {TestClip P2T Mix}
      {TestEcho P2T Mix}
      {TestFade P2T Mix}
      {TestCut P2T Mix}
      {AssertEquals {Mix P2T nil} nil 'nil music'}
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   proc {Test Mix P2T}
      {Property.put print print(width:100)}
      {Property.put print print(depth:100)}
      {System.show 'tests have started'}
      {TestP2T P2T}
      {System.show 'P2T tests have run'}
      {TestMix P2T Mix}
      {System.show 'Mix tests have run'}
      {System.show test(passed:@PassedTests total:@TotalTests)}
   end
end