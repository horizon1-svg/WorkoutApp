import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

const bg = Color(0xFF0C0C0B);
const surface = Color(0xFF191817);
const line = Color(0xFF292826);
const muted = Color(0xFF9C9891);
const red = Color(0xFFB43418);
const brightRed = Color(0xFFE04A22);
const redSoft = Color(0xFF35150F);
const text = Color(0xFFF3F0EA);
const panel = Color(0xFF141413);
const panel2 = Color(0xFF1B1A18);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.load();
  runApp(const WorkoutApp());
}

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Workout',
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(primary: brightRed, surface: surface),
      scaffoldBackgroundColor: bg,
      useMaterial3: true,
      fontFamily: 'sans-serif',
      inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: surface, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none)),
      appBarTheme: const AppBarTheme(elevation: 0, surfaceTintColor: Colors.transparent, titleTextStyle: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w900)),
    ),
    home: const HomeShell(),
  );
}

enum ExerciseMode { reps, time }

class Exercise {
  String name;
  int sets;
  int reps;
  ExerciseMode mode;
  int seconds;
  Exercise({required this.name, required this.sets, this.reps = 0, this.mode = ExerciseMode.reps, this.seconds = 180});
  Exercise copy() => Exercise(name: name, sets: sets, reps: reps, mode: mode, seconds: seconds);
}

final Map<String, List<Exercise>> workouts = {
  'PUSH A': [
    Exercise(name: 'Weighted Push-ups', sets: 3, reps: 15),
    Exercise(name: 'Weighted Decline Push-ups', sets: 3, reps: 15),
    Exercise(name: 'Wide Push-ups', sets: 3, reps: 15),
    Exercise(name: 'Archer Push-up Progression', sets: 3),
    Exercise(name: 'Lateral Raises', sets: 4, reps: 15),
    Exercise(name: 'Rear Delt Exercise', sets: 3, reps: 15),
    Exercise(name: 'Dips', sets: 3, reps: 15),
  ],
  'PUSH B': [
    Exercise(name: 'Pike Push-ups', sets: 3), Exercise(name: 'Lateral Raises', sets: 4, reps: 15),
    Exercise(name: 'Rear Delt Exercise', sets: 3, reps: 15), Exercise(name: 'Weighted Push-ups', sets: 2, reps: 15),
    Exercise(name: 'Weighted Decline Push-ups', sets: 2, reps: 15), Exercise(name: 'Archer Push-up Progression', sets: 3),
    Exercise(name: 'Dips', sets: 3, reps: 15),
  ],
  'PULL A': [
    Exercise(name: 'Pull-ups', sets: 3, reps: 15), Exercise(name: 'Wide Pull-ups', sets: 3, reps: 15),
    Exercise(name: 'Chin-ups', sets: 3, reps: 15), Exercise(name: 'Bent-Over Rows', sets: 3, reps: 15),
    Exercise(name: 'Hammer Curl', sets: 3, reps: 15), Exercise(name: 'Biceps Curl', sets: 3, reps: 15),
  ],
  'PULL B': [
    Exercise(name: 'Pull-ups', sets: 3), Exercise(name: 'Wide Pull-ups', sets: 3),
    Exercise(name: 'Good Morning — Backpack', sets: 3, reps: 12), Exercise(name: 'Low Back Extension', sets: 3, reps: 15),
    Exercise(name: 'Wrist Curl', sets: 3, mode: ExerciseMode.time, seconds: 60),
    Exercise(name: 'Wrist Extension', sets: 3, mode: ExerciseMode.time, seconds: 60),
    Exercise(name: 'Reverse Curl', sets: 3, reps: 15),
  ],
  'LEGS A': [
    Exercise(name: 'Weighted Squat — Backpack', sets: 3, reps: 8),
    Exercise(name: 'Bulgarian Split Squat', sets: 3, reps: 8),
    Exercise(name: 'Couch Lift / Couch Deadlift', sets: 3, reps: 8),
    Exercise(name: 'Lateral / Cossack-type Movement', sets: 3, reps: 8),
    Exercise(name: 'Wide-Stance Couch Squat', sets: 3, reps: 8),
    Exercise(name: 'Single-Leg Calf Raise', sets: 3, reps: 8),
    Exercise(name: 'Side Dips', sets: 3, reps: 10), Exercise(name: 'Leg Raises', sets: 3, reps: 10), Exercise(name: 'V-Ups', sets: 3, reps: 10),
  ],
  'LEGS B': [
    Exercise(name: 'Weighted Squat — Backpack', sets: 3, reps: 8), Exercise(name: 'Bulgarian Split Squat', sets: 3, reps: 8),
    Exercise(name: 'Couch Lift / Couch Deadlift', sets: 3, reps: 8), Exercise(name: 'Single-Leg Calf Raise', sets: 3, reps: 8),
    Exercise(name: 'Side Dips', sets: 3, reps: 15), Exercise(name: 'Leg Raises', sets: 3, reps: 15),
    Exercise(name: 'V-Ups', sets: 3, reps: 15), Exercise(name: 'Hollow Body Hold', sets: 3, mode: ExerciseMode.time, seconds: 60),
  ],
};

List<Exercise> cloneWorkout(String name) => workouts[name]!.map((e) => e.copy()).toList();

class SessionRecord {
  final String date;
  final String workout;
  final int duration;
  final int exercises;
  final int sets;
  final int skipped;
  SessionRecord({required this.date, required this.workout, required this.duration, required this.exercises, required this.sets, required this.skipped});
  Map<String, dynamic> toJson() => {'date': date, 'workout': workout, 'duration': duration, 'exercises': exercises, 'sets': sets, 'skipped': skipped};
  factory SessionRecord.fromJson(Map<String, dynamic> j) => SessionRecord(date: j['date'], workout: j['workout'], duration: j['duration'], exercises: j['exercises'], sets: j['sets'], skipped: j['skipped']);
}


class ActiveWorkoutSnapshot {
  final String workout;
  final int exerciseIndex;
  final int setIndex;
  final int remaining;
  final int sessionSeconds;
  final int completedSets;
  final int skipped;
  final String phase; // set, rest, timeup
  final int restRemaining;
  final List<Map<String,dynamic>> exercises;
  ActiveWorkoutSnapshot({required this.workout,required this.exerciseIndex,required this.setIndex,required this.remaining,required this.sessionSeconds,required this.completedSets,required this.skipped,required this.phase,required this.restRemaining,required this.exercises});
  Map<String,dynamic> toJson()=>{'workout':workout,'exerciseIndex':exerciseIndex,'setIndex':setIndex,'remaining':remaining,'sessionSeconds':sessionSeconds,'completedSets':completedSets,'skipped':skipped,'phase':phase,'restRemaining':restRemaining,'exercises':exercises};
  factory ActiveWorkoutSnapshot.fromJson(Map<String,dynamic> j)=>ActiveWorkoutSnapshot(workout:j['workout'],exerciseIndex:j['exerciseIndex'],setIndex:j['setIndex'],remaining:j['remaining'],sessionSeconds:j['sessionSeconds'],completedSets:j['completedSets'],skipped:j['skipped'],phase:j['phase'],restRemaining:j['restRemaining'],exercises:(j['exercises'] as List).cast<Map>().map((e)=>Map<String,dynamic>.from(e)).toList());
}

Map<String,dynamic> exerciseJson(Exercise e)=>{'name':e.name,'sets':e.sets,'reps':e.reps,'mode':e.mode.index,'seconds':e.seconds};
Exercise exerciseFromJson(Map<String,dynamic> j)=>Exercise(name:j['name'],sets:j['sets'],reps:j['reps'],mode:ExerciseMode.values[j['mode']],seconds:j['seconds']);

class AppStore {
  static late SharedPreferences prefs;
  static final List<SessionRecord> history = [];
  static final Set<String> restDays = {};
  static ActiveWorkoutSnapshot? active;
  static bool soundEnabled = true;
  static bool keepScreenAwake = true;
  static Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('history');
    if (raw != null) history.addAll((jsonDecode(raw) as List).map((e) => SessionRecord.fromJson(e)));
    restDays.addAll(prefs.getStringList('restDays') ?? []);
    soundEnabled = prefs.getBool('soundEnabled') ?? true;
    keepScreenAwake = prefs.getBool('keepScreenAwake') ?? true;
    final activeRaw = prefs.getString('activeWorkout');
    if (activeRaw != null) { try { active = ActiveWorkoutSnapshot.fromJson(jsonDecode(activeRaw)); } catch (_) { active = null; } }
  }
  static Future<void> save() async {
    await prefs.setString('history', jsonEncode(history.map((e) => e.toJson()).toList()));
    await prefs.setStringList('restDays', restDays.toList());
    if (active == null) { await prefs.remove('activeWorkout'); } else { await prefs.setString('activeWorkout', jsonEncode(active!.toJson())); }
    await prefs.setBool('soundEnabled', soundEnabled);
    await prefs.setBool('keepScreenAwake', keepScreenAwake);
  }
  static Future<void> clearActive() async { active=null; await prefs.remove('activeWorkout'); }
  static bool didTrainOrRest(DateTime d) {
    final key = dayKey(d);
    return history.any((x) => x.date == key) || restDays.contains(key);
  }
  static int get streak {
    var d = DateTime.now();
    if (!didTrainOrRest(d)) d = d.subtract(const Duration(days: 1));
    var count = 0;
    while (didTrainOrRest(d)) { count++; d = d.subtract(const Duration(days: 1)); }
    return count;
  }
  static String dayKey(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: tab, children: const [HomeContent(), StreakScreen(), HistoryScreen()]),
    bottomNavigationBar: NavigationBar(
      height: 72,
      backgroundColor: const Color(0xFF10100F),
      indicatorColor: redSoft,
      selectedIndex: tab,
      onDestinationSelected: (i) => setState(() => tab = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'HOME'),
        NavigationDestination(icon: Icon(Icons.local_fire_department_outlined), selectedIcon: Icon(Icons.local_fire_department), label: 'STREAK'),
        NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history_rounded), label: 'HISTORY'),
      ],
    ),
  );
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});
  @override State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TRAINING', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
            SizedBox(height: 4),
            Text("LET'S TRAIN.", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.2)),
          ])),
          Container(width: 42, height: 42, decoration: BoxDecoration(color: panel2, borderRadius: BorderRadius.circular(13)), child: IconButton(icon: const Icon(Icons.settings_outlined, size: 20, color: muted), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())))),
        ]),
        const SizedBox(height: 34),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF26100C), Color(0xFF151312)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF472016)),
          ),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.local_fire_department, color: Colors.white)),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CURRENT STREAK', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
              SizedBox(height: 2),
              Text('${AppStore.streak} DAYS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ])),
            const Icon(Icons.arrow_forward_ios, size: 13, color: muted),
          ]),
        ),
        const SizedBox(height: 34),
        const Text('WHAT ARE YOU', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.7)),
        const SizedBox(height: 3),
        const Text('TRAINING TODAY?', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
        const SizedBox(height: 18),
        for (final row in [['PUSH A','PUSH B'],['PULL A','PULL B'],['LEGS A','LEGS B']]) ...[
          Row(children: [Expanded(child: Choice(name: row[0])), const SizedBox(width: 10), Expanded(child: Choice(name: row[1]))]),
          const SizedBox(height: 10),
        ],
        Choice(name: 'REST', full: true),
        if (AppStore.active != null) ...[
          const SizedBox(height: 20),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveWorkoutScreen.resume(snapshot: AppStore.active!))).then((_) => setState(() {})),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: line)),
              child: Row(children: [
                const Icon(Icons.play_arrow_rounded, color: brightRed), const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('WORKOUT IN PROGRESS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)), SizedBox(height: 3), Text('Resume your paused session', style: TextStyle(color: muted, fontSize: 11))])),
                const Icon(Icons.arrow_forward_ios, size: 12, color: muted),
              ]),
            ),
          ),
        ],
      ],
    ),
  );
}

class Choice extends StatelessWidget {
  final String name;
  final bool full;
  const Choice({super.key, required this.name, this.full = false});
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(15),
    onTap: () async {
      if (name == 'REST') {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const RestDayScreen()));
      } else {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => SetupScreen(workoutName: name)));
      }
    },
    child: Container(
      height: full ? 58 : 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: line)),
      child: Row(children: [
        Container(width: 4, height: 25, decoration: BoxDecoration(color: name == 'REST' ? const Color(0xFF5B5751) : brightRed, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 12),
        Text(name, style: TextStyle(fontSize: full ? 15 : 16, fontWeight: FontWeight.w900, letterSpacing: .3)),
        const Spacer(),
        const Icon(Icons.arrow_forward_ios, size: 12, color: muted),
      ]),
    ),
  );
}

class SetupScreen extends StatefulWidget {
  final String workoutName;
  const SetupScreen({super.key, required this.workoutName});
  @override State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late List<Exercise> exercises;
  @override void initState() { super.initState(); exercises = cloneWorkout(widget.workoutName); }
  Future<void> editExercise(int i) async { final result = await showDialog<int>(context: context, builder: (_) => SetEditor(exercise: exercises[i])); if (result != null) setState(() => exercises[i].sets = result); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.workoutName), backgroundColor: Colors.transparent, centerTitle: false),
    body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(22, 4, 22, 16), child: Row(children: [
        const Text('YOUR WORKOUT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.4, fontSize: 12)),
        const Spacer(), Text('${exercises.length.toString().padLeft(2, '0')} EXERCISES', style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
      ])),
      Expanded(child: ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 22), itemCount: exercises.length,
        onReorder: (a,b) => setState(() { if (b > a) b--; final e = exercises.removeAt(a); exercises.insert(b, e); }),
        itemBuilder: (_, i) {
          final e = exercises[i];
          return Container(
            key: ObjectKey(e), margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(15), border: Border.all(color: line)),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(14, 5, 8, 5),
              leading: SizedBox(width: 30, child: Text('${i+1}'.padLeft(2,'0'), style: const TextStyle(color: brightRed, fontWeight: FontWeight.w900))),
              title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(e.mode == ExerciseMode.time ? '${fmt(e.seconds)} · ${e.sets} SETS' : e.reps == 0 ? 'MAX · ${e.sets} SETS' : '${e.reps} REPS · ${e.sets} SETS', style: const TextStyle(color: muted, fontSize: 11))),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () => editExercise(i), icon: const Icon(Icons.tune, size: 18)), const Icon(Icons.drag_handle, color: muted)]),
            ),
          );
        },
      )),
      Padding(padding: const EdgeInsets.fromLTRB(22, 10, 22, 20), child: SizedBox(width: double.infinity, height: 58, child: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: brightRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WarmupScreen(workoutName: widget.workoutName, exercises: exercises))),
        child: const Text('START WORKOUT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
      )))
    ]),
  );
}

class SetEditor extends StatefulWidget { final Exercise exercise; const SetEditor({super.key,required this.exercise}); @override State<SetEditor> createState()=>_SetEditorState(); }
class _SetEditorState extends State<SetEditor>{late int sets;@override void initState(){super.initState();sets=widget.exercise.sets;}@override Widget build(BuildContext context)=>AlertDialog(backgroundColor:surface,title:Text(widget.exercise.name),content:Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton(onPressed:()=>setState(()=>sets=sets>1?sets-1:1),icon:const Icon(Icons.remove)),Text('$sets SETS',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:20)),IconButton(onPressed:()=>setState(()=>sets++),icon:const Icon(Icons.add))]),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('CANCEL')),FilledButton(onPressed:()=>Navigator.pop(context,sets),child:const Text('DONE'))]);}

class WarmupItem { final String name; final int seconds; WarmupItem(this.name,this.seconds); }

List<WarmupItem> warmupFor(String workout) {
  if (workout.startsWith('PUSH')) {
    return [
      WarmupItem('Jumping Jacks', 60),
      WarmupItem('Wrist Joint Warm-up', 60),
      WarmupItem('Shoulder Warm-up', 60),
    ];
  }
  if (workout.startsWith('PULL')) {
    return [
      WarmupItem('Dead Hang', 60),
      WarmupItem('Rest', 180),
      WarmupItem('Scapular Retraction', 60),
    ];
  }
  return [WarmupItem('Jumping Jacks', 60)];
}

class WarmupScreen extends StatefulWidget {
  final String workoutName; final List<Exercise> exercises;
  const WarmupScreen({super.key,required this.workoutName,required this.exercises});
  @override State<WarmupScreen> createState()=>_WarmupScreenState();
}

class _WarmupScreenState extends State<WarmupScreen> with WidgetsBindingObserver {
  late List<WarmupItem> items; int step=0,remaining=60; Timer? timer; bool paused=false;
  WarmupItem get item => items[step];
  @override void initState(){super.initState(); WidgetsBinding.instance.addObserver(this); items=warmupFor(widget.workoutName); remaining=item.seconds; _applyWakelock(); _start();}
  Future<void> _applyWakelock() async { if (AppStore.keepScreenAwake) await WakelockPlus.enable(); else await WakelockPlus.disable(); }
  void _start(){timer?.cancel(); paused=false; timer=Timer.periodic(const Duration(seconds:1),(_){if(!mounted||paused)return; if(remaining<=1){remaining=0; timer?.cancel(); if (AppStore.soundEnabled) SystemSound.play(SystemSoundType.alert); setState((){});} else {setState(()=>remaining--);}});}
  void togglePause(){if(remaining==0)return; setState(()=>paused=!paused); if(!paused){timer?.cancel(); _start();} else timer?.cancel();}
  void next(){timer?.cancel(); if(step==items.length-1){Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>ActiveWorkoutScreen(workoutName:widget.workoutName,exercises:widget.exercises)));}else{setState(()=>step++);remaining=item.seconds;_start();}}
  void skipAll(){timer?.cancel();Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>ActiveWorkoutScreen(workoutName:widget.workoutName,exercises:widget.exercises)));}
  @override void dispose(){timer?.cancel();WidgetsBinding.instance.removeObserver(this);WakelockPlus.disable();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('WARM-UP'),backgroundColor:Colors.transparent,actions:[TextButton(onPressed:skipAll,child:const Text('SKIP'))]),
    body:Padding(padding:const EdgeInsets.fromLTRB(22,8,22,22),child:Column(children:[
      Row(children:[Text(widget.workoutName,style:const TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w900,letterSpacing:1.5)),const Spacer(),Text('${step+1} / ${items.length}',style:const TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w800))]),
      const SizedBox(height:12), LinearProgressIndicator(value:(step + (remaining==0?1:0))/items.length,backgroundColor:line,valueColor:const AlwaysStoppedAnimation(brightRed),minHeight:3),
      const Spacer(),
      Container(height:250,width:double.infinity,decoration:BoxDecoration(color:surface,borderRadius:BorderRadius.circular(20),border:Border.all(color:line)),clipBehavior:Clip.hardEdge,child:Padding(padding:const EdgeInsets.all(8),child:Image.asset(warmupImage(item.name),fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Center(child:Icon(Icons.fitness_center,size:72,color:muted))))),
      const SizedBox(height:22),
      Text(item.name.toUpperCase(),textAlign:TextAlign.center,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900)),
      const SizedBox(height:8),
      Text(item.name=='Rest'?'RECOVERY': 'PREPARE YOUR BODY',style:const TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w800,letterSpacing:1.2)),
      const SizedBox(height:14),
      Text(fmt(remaining),style:const TextStyle(fontSize:64,fontWeight:FontWeight.w900,letterSpacing:-2)),
      if(paused) const Text('PAUSED',style:TextStyle(color:brightRed,fontWeight:FontWeight.w900,letterSpacing:1.5)),
      const Spacer(),
      Row(children:[Expanded(child:OutlinedButton(onPressed:remaining==0?null:togglePause,style:OutlinedButton.styleFrom(foregroundColor:text,side:const BorderSide(color:line),minimumSize:const Size.fromHeight(52)),child:Text(paused?'RESUME':'PAUSE'))),const SizedBox(width:10),Expanded(child:FilledButton(onPressed:next,style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(52)),child:Text(remaining==0?(step==items.length-1?'START WORKOUT':'NEXT'):'SKIP')))]),
    ])),
  );
}

class ActiveWorkoutScreen extends StatefulWidget {
  final String workoutName; final List<Exercise> exercises; final ActiveWorkoutSnapshot? snapshot;
  const ActiveWorkoutScreen({super.key,required this.workoutName,required this.exercises}):snapshot=null;
  const ActiveWorkoutScreen.resume({super.key,required ActiveWorkoutSnapshot snapshot}):workoutName=snapshot.workout,exercises=const [],snapshot=snapshot;
  @override State<ActiveWorkoutScreen> createState()=>_ActiveWorkoutScreenState();
}
class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> with WidgetsBindingObserver {
  late List<Exercise> exercises; int exerciseIndex=0,setIndex=0,remaining=180,sessionSeconds=0,completedSets=0,skipped=0,restRemaining=180; String phase='set'; Timer? timer; bool timeUp=false; int _saveTick=0;
  Exercise get exercise=>exercises[exerciseIndex];
  int get targetSeconds=>exercise.mode==ExerciseMode.time?exercise.seconds:180;
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this); if(widget.snapshot!=null){final s=widget.snapshot!;exercises=s.exercises.map(exerciseFromJson).toList();exerciseIndex=s.exerciseIndex;setIndex=s.setIndex;remaining=s.remaining;sessionSeconds=s.sessionSeconds;completedSets=s.completedSets;skipped=s.skipped;phase=s.phase;restRemaining=s.restRemaining;timeUp=phase=='timeup';}else{exercises=widget.exercises.map((e)=>e.copy()).toList();} _startPhase(); _applyWakelock();}
  void _startPhase(){timer?.cancel(); if(phase=='rest'){remaining=restRemaining;} else if(phase=='set'){if(remaining<=0||remaining>targetSeconds)remaining=targetSeconds;} else return; timer=Timer.periodic(const Duration(seconds:1),(_){if(!mounted)return;sessionSeconds++;_saveTick++;if(phase=='rest'){if(remaining<=1){remaining=0;restRemaining=0;timer?.cancel();if (AppStore.soundEnabled) SystemSound.play(SystemSoundType.alert);setState((){phase='set';remaining=targetSeconds;});_save();}else{setState(()=>remaining--);restRemaining=remaining;}}else{if(remaining<=1){remaining=0;timer?.cancel();if (AppStore.soundEnabled) SystemSound.play(SystemSoundType.alert);setState(()=>timeUp=true);phase='timeup';_save();}else{setState(()=>remaining--);}} if(_saveTick>=5){_saveTick=0;_save();}});}
  Future<void> _save(){AppStore.active=ActiveWorkoutSnapshot(workout:widget.workoutName,exerciseIndex:exerciseIndex,setIndex:setIndex,remaining:remaining,sessionSeconds:sessionSeconds,completedSets:completedSets,skipped:skipped,phase:phase,restRemaining:restRemaining,exercises:exercises.map(exerciseJson).toList());return AppStore.save();}
  Future<void> completeSet() async {if(phase!='set'&&!timeUp)return;timer?.cancel();int? actual;if(exercise.mode==ExerciseMode.reps){actual=await showDialog<int>(context:context,builder:(_)=>RepsDialog(target:exercise.reps));if(actual==null){_startPhase();return;}}if(!mounted)return;completedSets++;if(setIndex<exercise.sets-1){setState(()=>setIndex++);phase='rest';restRemaining=180;remaining=180;await _save();_startPhase();}else{nextExercise();}}
  void nextExercise(){timer?.cancel();if(exerciseIndex<exercises.length-1){setState((){exerciseIndex++;setIndex=0;phase='set';remaining=targetSeconds;timeUp=false;});_save();_startPhase();}else{final totalSets=exercises.fold<int>(0,(a,e)=>a+e.sets);final exDone=exercises.where((e)=>true).length;AppStore.active=null;AppStore.save();Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>CompleteScreen(workoutName:widget.workoutName,duration:sessionSeconds,exercises:exDone,sets:completedSets,totalSets:totalSets,skipped:skipped)));}}
  void skipSet(){timer?.cancel();skipped++;if(setIndex<exercise.sets-1){setState(()=>setIndex++);phase='rest';restRemaining=180;remaining=180;_save();_startPhase();}else nextExercise();}
  void skipExercise(){timer?.cancel();skipped++;nextExercise();}
  Future<void> _applyWakelock() async { if (AppStore.keepScreenAwake) { await WakelockPlus.enable(); } else { await WakelockPlus.disable(); } }
  Future<void> leave()async{timer?.cancel();await _save();final yes=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(backgroundColor:surface,title:const Text('WORKOUT IN PROGRESS'),content:const Text('Are you sure you want to leave?\n\nYour current workout will be paused.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('CONTINUE')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('EXIT'))]));if(yes==true&&mounted){await _save();WakelockPlus.disable();Navigator.pop(context);}else if(mounted)_startPhase();}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.inactive||state==AppLifecycleState.paused){timer?.cancel();_save();}else if(state==AppLifecycleState.resumed){_startPhase();}}
  @override void dispose(){timer?.cancel();WidgetsBinding.instance.removeObserver(this);WakelockPlus.disable();super.dispose();}
  Widget _progress(double value) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: LinearProgressIndicator(value: value.clamp(0.0, 1.0), minHeight: 5, backgroundColor: line, valueColor: const AlwaysStoppedAnimation(brightRed)),
  );

  Widget _timerDial() {
    final total = phase == 'rest' ? 180 : targetSeconds;
    final value = total <= 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
    return SizedBox(
      width: 208, height: 208,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(width: 208, height: 208, child: CircularProgressIndicator(value: 1, strokeWidth: 9, color: line)),
        SizedBox(width: 208, height: 208, child: CircularProgressIndicator(value: value, strokeWidth: 9, strokeCap: StrokeCap.round, color: brightRed)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(phase == 'rest' ? 'REST' : timeUp ? "TIME'S UP" : 'TIME', style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 3),
          Text(fmt(remaining), style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1)),
        ]),
      ]),
    );
  }

  @override Widget build(BuildContext context) {
    final exerciseProgress = exercises.isEmpty ? 0.0 : exerciseIndex / exercises.length;
    final setProgress = exercise.sets == 0 ? 0.0 : setIndex / exercise.sets;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => leave(),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(onPressed: leave, icon: const Icon(Icons.close_rounded)),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.workoutName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            Text('EXERCISE ${(exerciseIndex + 1).toString().padLeft(2, '0')} / ${exercises.length}', style: const TextStyle(color: muted, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          ]),
          actions: [IconButton(onPressed: () => showModalBottomSheet(context: context, backgroundColor: surface, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.skip_next), title: const Text('Skip exercise'), onTap: () { Navigator.pop(context); skipExercise(); }), ListTile(leading: const Icon(Icons.close), title: const Text('Exit workout'), onTap: () { Navigator.pop(context); leave(); })]))), icon: const Icon(Icons.more_horiz_rounded))],
        ),
        body: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(22, 2, 22, 0), child: _progress(exerciseProgress)),
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 20), children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(exercise.name.toUpperCase(), style: const TextStyle(fontSize: 25, height: 1.0, fontWeight: FontWeight.w900, letterSpacing: -.5)),
                const SizedBox(height: 8),
                Text(phase == 'rest' ? 'RECOVER FOR THE NEXT SET' : timeUp ? 'YOU EXCEEDED THE TARGET' : exercise.mode == ExerciseMode.time ? 'TIME-BASED SET' : exercise.reps == 0 ? 'TARGET · MAX REPS' : 'TARGET · ${exercise.reps} REPS', style: const TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: redSoft, borderRadius: BorderRadius.circular(12)), child: Text(phase == 'rest' ? 'REST' : 'SET ${setIndex + 1}/${exercise.sets}', style: const TextStyle(color: brightRed, fontSize: 11, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 18),
            Container(height: 205, decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(22), border: Border.all(color: line)), clipBehavior: Clip.antiAlias, child: Stack(children: [
              Positioned.fill(child: Image.asset(exerciseImage(exercise.name), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.fitness_center_rounded, size: 72, color: muted)))),
              Positioned(left: 14, bottom: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: Colors.black.withOpacity(.72), borderRadius: BorderRadius.circular(9)), child: Text('${exerciseIndex + 1}'.padLeft(2, '0'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)))),
            ])),
            const SizedBox(height: 24),
            if (timeUp) Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: redSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: red)), child: Column(children: [const Text("TIME'S UP", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 4), const Text('You exceeded the target time.', style: TextStyle(color: muted)), const SizedBox(height: 12), SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: () { setState(() { timeUp = false; phase = 'set'; }); _save(); _startPhase(); }, child: const Text("I'M DONE")))]))
            else if (phase == 'rest') ...[
              Center(child: _timerDial()),
              const SizedBox(height: 20),
              Row(children: [Expanded(child: _smallAction('+30 SEC', () { setState(() => remaining += 30); restRemaining = remaining; })), const SizedBox(width: 10), Expanded(child: _smallAction('+1 MIN', () { setState(() => remaining += 60); restRemaining = remaining; }))]),
            ] else ...[
              Center(child: _timerDial()),
              const SizedBox(height: 12),
              Center(child: Text(exercise.mode == ExerciseMode.time ? fmt(exercise.seconds) : exercise.reps == 0 ? 'MAX REPS' : '${exercise.reps} REPS', style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1))),
              const SizedBox(height: 18),
              _progress(setProgress),
            ],
          ])),
          Container(padding: const EdgeInsets.fromLTRB(22, 12, 22, 16), decoration: BoxDecoration(color: const Color(0xFF10100F), border: Border(top: BorderSide(color: line))), child: phase == 'rest' ? Column(children: [SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: () { timer?.cancel(); setState(() { phase = 'set'; remaining = targetSeconds; }); _save(); _startPhase(); }, child: const Text('SKIP REST'))), const SizedBox(height: 7), TextButton(onPressed: () { timer?.cancel(); setState(() { phase = 'set'; remaining = targetSeconds; }); _save(); _startPhase(); }, child: const Text('START SET NOW'))]) : timeUp ? const SizedBox.shrink() : Column(children: [SizedBox(width: double.infinity, height: 56, child: FilledButton(onPressed: completeSet, child: Text(exercise.mode == ExerciseMode.time ? 'COMPLETE SET' : 'COMPLETE SET'))), const SizedBox(height: 2), Row(children: [Expanded(child: TextButton(onPressed: skipSet, child: const Text('SKIP SET'))), Expanded(child: TextButton(onPressed: skipExercise, child: const Text('SKIP EXERCISE')))])]))),
        ])),
      ),
    );
  }

  Widget _smallAction(String label, VoidCallback onTap) => OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(foregroundColor: text, side: const BorderSide(color: line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)));


class RepsDialog extends StatefulWidget{final int target;const RepsDialog({super.key,required this.target});@override State<RepsDialog> createState()=>_RepsDialogState();}
class _RepsDialogState extends State<RepsDialog>{late TextEditingController c;@override void initState(){super.initState();c=TextEditingController(text:widget.target==0?'':'${widget.target}');}@override Widget build(BuildContext context)=>AlertDialog(backgroundColor:surface,title:const Text('SET COMPLETE'),content:TextField(controller:c,keyboardType:TextInputType.number,autofocus:true,decoration:const InputDecoration(labelText:'Actual reps')),actions:[FilledButton(onPressed:()=>Navigator.pop(context,int.tryParse(c.text)),child:const Text('CONFIRM'))]);@override void dispose(){c.dispose();super.dispose();}}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SETTINGS'), backgroundColor: Colors.transparent),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
      children: [
        const Text('TRAINING', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.7)),
        const SizedBox(height: 10),
        _SettingRow(
          title: 'Keep Screen Awake',
          subtitle: 'Prevent the display from sleeping during warm-up and workouts.',
          value: AppStore.keepScreenAwake,
          onChanged: (v) async { setState(() => AppStore.keepScreenAwake = v); await AppStore.save(); },
        ),
        const SizedBox(height: 28),
        const Text('SOUND', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.7)),
        const SizedBox(height: 10),
        _SettingRow(
          title: 'System Alert Sound',
          subtitle: 'Play the phone system alert when a timer reaches zero.',
          value: AppStore.soundEnabled,
          onChanged: (v) async { setState(() => AppStore.soundEnabled = v); await AppStore.save(); },
        ),
        const SizedBox(height: 28),
        const Text('ABOUT', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.7)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: line)),
          child: const Row(children: [Icon(Icons.fitness_center, color: brightRed), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('WORKOUT', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('Personal training tracker · V0.7', style: TextStyle(color: muted, fontSize: 12))]))]),
        ),
      ],
    ),
  );
}

class _SettingRow extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingRow({required this.title, required this.subtitle, required this.value, required this.onChanged});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
    decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: line)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), const SizedBox(height: 5), Text(subtitle, style: const TextStyle(color: muted, fontSize: 11, height: 1.3))])),
      Switch(value: value, activeThumbColor: Colors.white, activeTrackColor: brightRed, onChanged: onChanged),
    ]),
  );
}

class RestScreen extends StatefulWidget{const RestScreen({super.key});@override State<RestScreen> createState()=>_RestScreenState();}
class _RestScreenState extends State<RestScreen>{int remaining=180;Timer?timer;@override void initState(){super.initState();timer=Timer.periodic(const Duration(seconds:1),(_){if(!mounted)return;if(remaining>0)setState(()=>remaining--);});}void add(int s)=>setState(()=>remaining+=s);@override void dispose(){timer?.cancel();super.dispose();}@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('REST'),backgroundColor:Colors.transparent),body:Padding(padding:const EdgeInsets.all(22),child:Column(children:[const Spacer(),const Text('REST',style:TextStyle(color:muted,fontWeight:FontWeight.w900,letterSpacing:2)),const SizedBox(height:16),Text(fmt(remaining),style:const TextStyle(fontSize:72,fontWeight:FontWeight.w900)),const SizedBox(height:24),Row(mainAxisAlignment:MainAxisAlignment.center,children:[TextButton(onPressed:()=>add(30),child:const Text('+30 SEC')),TextButton(onPressed:()=>add(60),child:const Text('+1 MIN'))]),TextButton(onPressed:()=>setState(()=>remaining=180),child:const Text('RESET TO 03:00')),const Spacer(),SizedBox(width:double.infinity,height:54,child:FilledButton(onPressed:(){timer?.cancel();Navigator.pop(context,false);},child:const Text('DONE'))),TextButton(onPressed:(){timer?.cancel();Navigator.pop(context,true);},child:const Text('SKIP REST'))])));}

class CompleteScreen extends StatelessWidget{final String workoutName;final int duration,exercises,sets,totalSets,skipped;const CompleteScreen({super.key,required this.workoutName,required this.duration,required this.exercises,required this.sets,required this.totalSets,required this.skipped});@override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Padding(padding:const EdgeInsets.all(28),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Spacer(),const Text('WORKOUT',textAlign:TextAlign.center,style:TextStyle(color:muted,fontWeight:FontWeight.w800,letterSpacing:3)),const Text('COMPLETE',textAlign:TextAlign.center,style:TextStyle(fontSize:44,fontWeight:FontWeight.w900)),const SizedBox(height:36),Text(workoutName,textAlign:TextAlign.center,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800)),const SizedBox(height:10),Text(fmt(duration),textAlign:TextAlign.center,style:const TextStyle(fontSize:34,fontWeight:FontWeight.w900)),const SizedBox(height:26),Text('$sets / $totalSets SETS',textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w800)),Text('$exercises EXERCISES  ·  $skipped SKIPPED',textAlign:TextAlign.center,style:const TextStyle(color:muted)),const Spacer(),SizedBox(height:56,child:FilledButton(onPressed:()async{AppStore.history.insert(0,SessionRecord(date:AppStore.dayKey(DateTime.now()),workout:workoutName,duration:duration,exercises:exercises,sets:sets,skipped:skipped));await AppStore.save();if(context.mounted)Navigator.popUntil(context,(r)=>r.isFirst);},child:const Text('FINISH'))])));}

class RestDayScreen extends StatelessWidget{const RestDayScreen({super.key});@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(backgroundColor:Colors.transparent),body:SafeArea(child:Padding(padding:const EdgeInsets.all(28),child:Column(children:[const Spacer(),const Text('REST DAY',style:TextStyle(fontSize:42,fontWeight:FontWeight.w900)),const SizedBox(height:12),const Text('Recovery is part of training.',style:TextStyle(color:muted,fontSize:17)),const SizedBox(height:24),Text('🔥 Streak: ${AppStore.streak} days',style:const TextStyle(fontWeight:FontWeight.w800)),const Spacer(),SizedBox(width:double.infinity,height:56,child:FilledButton(onPressed:()async{AppStore.restDays.add(AppStore.dayKey(DateTime.now()));await AppStore.save();if(context.mounted)Navigator.pop(context);},child:const Text('COMPLETE REST DAY')))])));}

class StreakScreen extends StatelessWidget{const StreakScreen({super.key});@override Widget build(BuildContext context){final now=DateTime.now();final monday=now.subtract(Duration(days:now.weekday-1));return SafeArea(child:ListView(padding:const EdgeInsets.all(22),children:[const SizedBox(height:20),const Text('STREAK',style:TextStyle(color:muted,fontWeight:FontWeight.w900,letterSpacing:2)),const SizedBox(height:8),Text('${AppStore.streak}',style:const TextStyle(fontSize:76,fontWeight:FontWeight.w900)),const Text('DAY STREAK',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:2)),const SizedBox(height:40),const Text('THIS WEEK',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1.5)),const SizedBox(height:16),...List.generate(7,(i){final d=monday.add(Duration(days:i));final key=AppStore.dayKey(d);final session=AppStore.history.where((x)=>x.date==key).firstOrNull;final done=session!=null||AppStore.restDays.contains(key);return Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Row(children:[SizedBox(width:42,child:Text(['MON','TUE','WED','THU','FRI','SAT','SUN'][i],style:const TextStyle(fontWeight:FontWeight.w800))),Icon(done?Icons.check_circle:Icons.remove,color:done?brightRed:Color(0xFF55524D),size:18),const SizedBox(width:12),Text(session?.workout??(AppStore.restDays.contains(key)?'REST':'—'),style:const TextStyle(fontWeight:FontWeight.w700))]));})]));}}

class HistoryScreen extends StatelessWidget{const HistoryScreen({super.key});@override Widget build(BuildContext context)=>SafeArea(child:ListView(padding:const EdgeInsets.all(22),children:[const SizedBox(height:20),const Text('HISTORY',style:TextStyle(fontSize:32,fontWeight:FontWeight.w900)),const SizedBox(height:30),if(AppStore.history.isEmpty)const Text('NO COMPLETED WORKOUTS YET',style:TextStyle(color:muted)) else ...AppStore.history.map((x)=>Container(padding:const EdgeInsets.symmetric(vertical:18),decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:line))),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(x.date,style:const TextStyle(color:muted,fontSize:12)),const SizedBox(height:4),Text(x.workout,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17)),if(x.skipped>0)Text('${x.skipped} skipped',style:const TextStyle(color:muted,fontSize:12))])),Text(fmt(x.duration),style:const TextStyle(fontWeight:FontWeight.w800))]))]));}

String exerciseImage(String name) {
  final n = name.toLowerCase();
  if (n.contains('weighted push-ups')) return 'assets/exercises/push1.jpg';
  if (n.contains('weighted decline')) return 'assets/exercises/push2.jpg';
  if (n.contains('wide push')) return 'assets/exercises/push3.jpg';
  if (n.contains('archer')) return 'assets/exercises/push4.jpg';
  if (n == 'lateral raises') return 'assets/exercises/push5.jpg';
  if (n.contains('rear delt')) return 'assets/exercises/push6.jpg';
  if (n == 'dips') return 'assets/exercises/push7.jpg';
  if (n == 'pike push-ups') return 'assets/exercises/push6.jpg';
  if (n == 'pull-ups') return 'assets/exercises/pull1.jpg';
  if (n == 'wide pull-ups') return 'assets/exercises/pull2.jpg';
  if (n == 'chin-ups') return 'assets/exercises/pull4.jpg';
  if (n.contains('bent-over')) return 'assets/exercises/pull3.jpg';
  if (n.contains('hammer curl')) return 'assets/exercises/pull6.jpg';
  if (n.contains('biceps curl')) return 'assets/exercises/pull7.jpg';
  if (n.contains('good morning')) return 'assets/exercises/legsB1.jpg';
  if (n.contains('low back')) return 'assets/exercises/legsB4.jpg';
  if (n.contains('wrist')) return 'assets/exercises/front_raises.png';
  if (n.contains('reverse curl')) return 'assets/exercises/pull5.jpg';
  if (n.contains('squat')) return 'assets/exercises/legs2.jpg';
  if (n.contains('bulgarian')) return 'assets/exercises/legs1.jpg';
  if (n.contains('couch')) return 'assets/exercises/legs3.jpg';
  if (n.contains('lateral') || n.contains('cossack')) return 'assets/exercises/legs4.jpg';
  if (n.contains('calf')) return 'assets/exercises/legs6.jpg';
  if (n.contains('side dips')) return 'assets/exercises/push5.jpg';
  if (n.contains('leg raises')) return 'assets/exercises/legsB2.jpg';
  if (n.contains('v-ups')) return 'assets/exercises/legsB3.jpg';
  if (n.contains('hollow')) return 'assets/exercises/legsB2.jpg';
  return 'assets/exercises/all_exercises_sheet.png';
}

String warmupImage(String name) {
  final n = name.toLowerCase();
  if (n.contains('jumping')) return 'assets/exercises/warm1.jpg';
  if (n.contains('wrist')) return 'assets/exercises/warm2.jpg';
  if (n.contains('shoulder')) return 'assets/exercises/warm2.jpg';
  if (n.contains('hang')) return 'assets/exercises/warm3.jpg';
  if (n.contains('scap')) return 'assets/exercises/warm8.jpg';
  return 'assets/exercises/all_exercises_sheet.png';
}

String fmt(int seconds){final m=(seconds~/60).toString().padLeft(2,'0');final s=(seconds%60).toString().padLeft(2,'0');final h=seconds~/3600;if(h>0){final mm=((seconds%3600)~/60).toString().padLeft(2,'0');return '${h.toString().padLeft(2,'0')}:$mm:$s';}return '$m:$s';}
