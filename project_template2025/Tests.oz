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
      
      P4 = [
         note(name:c octave:4 sharp:false duration:2.0 instrument:none)
         note(name:e octave:4 sharp:false duration:0.5 instrument:none)
         silence(duration:1.5)
      ]
   in
      {AssertEquals {P2T P4} P4 "TestDuration: simple durations"}
   end

   proc {TestDuration_LongNote P2T}
      P = [note(name:g octave:3 sharp:false duration:5.0 instrument:none)]
   in
      {AssertEquals {P2T P} P "TestDuration: long note"}
   end

   proc {TestDuration_SilenceDifferentDuration P2T}
      P = [silence(duration:0.25)]
      E = [silence(duration:0.25)]
   in
      {AssertEquals {P2T P} E "TestDuration: silence with custom duration"}
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

   proc {TestTranspose P2T}
      skip
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
      {TestDuration_LongNote P2T}
      {TestDuration_SilenceDifferentDuration P2T}
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
      {TestTranspose P2T}
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
      skip
   end
   
   proc {TestWave P2T Mix}
      skip
   end

   proc {TestMerge P2T Mix}
      skip
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
      {TestWave P2T Mix}
      {TestMerge P2T Mix}
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