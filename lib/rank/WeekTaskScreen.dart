import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'model/task_model.dart';

class WeeklyTasksPage extends StatefulWidget {
  @override
  _WeeklyTasksPageState createState() => _WeeklyTasksPageState();
}

class _WeeklyTasksPageState extends State<WeeklyTasksPage> {
  List<DailyTask> weeklyTasks = [
    DailyTask(name: 'Complete 5 workouts', isCompleted: false, xp: 150, hasClaimedXP: false),
    DailyTask(name: 'Finish a book', isCompleted: false, xp: 100, hasClaimedXP: false),
    DailyTask(name: 'Cook 3 new recipes', isCompleted: false, xp: 80, hasClaimedXP: false),
  ];

  void completeTask(int index) {
    setState(() {
      weeklyTasks[index].isCompleted = !weeklyTasks[index].isCompleted;
      if (weeklyTasks[index].isCompleted) {
        // 경험치 지급 로직 추가
        if (kDebugMode) {
          print('Experience Points Earned: ${weeklyTasks[index].xp}');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Tasks')),
      body: ListView.builder(
        itemCount: weeklyTasks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(weeklyTasks[index].name),
            trailing: Checkbox(
              value: weeklyTasks[index].isCompleted,
              onChanged: (bool? value) {
                completeTask(index);
              },
            ),
          );
        },
      ),
    );
  }
}
