import 'package:flutter/material.dart';
import 'package:time_planner/src/time_planner_date_time.dart';
import 'package:time_planner/src/config/global_config.dart' as config;
import 'dart:math';

/// Widget that show on time planner as the tasks
class TimePlannerTask extends StatelessWidget {
  /// Minutes duration of task or object
  final int minutesDuration;

  /// Days duration of task or object, default is 1
  final int? daysDuration;

  /// When this task will be happen
  final TimePlannerDateTime dateTime;

  /// Background color of task
  final Color? color;

  /// This will be happen when user tap on task, for example show a dialog or navigate to other page
  final Function? onTap;

  /// Show this child on the task
  ///
  /// Typically an [Text].
  final Widget? child;

  /// parameter to set space from left, to set it: config.cellWidth! * dateTime.day.toDouble()
  final double? leftSpace;

  /// parameter to set width of task, to set it: (config.cellWidth!.toDouble() * (daysDuration ?? 1)) -config.horizontalTaskPadding!
  final double? widthTask;

  List<TimePlannerTask> _allTasksInTheDay = const [];

  /// Widget that show on time planner as the tasks
  TimePlannerTask(
      {Key? key,
      required this.minutesDuration,
      required this.dateTime,
      this.daysDuration,
      this.color,
      this.onTap,
      this.child,
      this.leftSpace,
      this.widthTask})
      : super(key: key);

  void setAllTasks(Map<String, List<TimePlannerTask>> allTasks) {
    String key = dateTime.day.toString();
    this._allTasksInTheDay = allTasks[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final (offset, widthPercentage, padding) =
        findTaskPositionElements(_allTasksInTheDay, this);
    double width = ((config.cellWidth!.toDouble() ?? padding) - padding) *
        widthPercentage.toDouble();
    double dayOffset = offset * (config.cellWidth!.toDouble() ?? 0) +
        this.dateTime.day * config.cellWidth!;
    return Positioned(
      top: ((config.cellHeight! * (dateTime.hour - config.startHour)) +
              ((dateTime.minutes * config.cellHeight!) / 60))
          .toDouble(),
      left: config.cellWidth! * dateTime.day.toDouble() +
          (leftSpace ?? 0.0) +
          dayOffset,
      child: SizedBox(
        width: widthTask,
        child: Padding(
          padding:
              EdgeInsets.only(left: config.horizontalTaskPadding!.toDouble()),
          child: Material(
            elevation: 3,
            borderRadius: config.borderRadius,
            child: Stack(
              children: [
                InkWell(
                  onTap: onTap as void Function()? ?? () {},
                  child: Container(
                    height: ((minutesDuration.toDouble() * config.cellHeight!) /
                        60), //60 minutes
                    width: (width * (daysDuration ?? 1)),
                    // (daysDuration! >= 1 ? daysDuration! : 1)),
                    decoration: BoxDecoration(
                        borderRadius: config.borderRadius,
                        color: color ?? Theme.of(context).primaryColor),
                    child: Center(
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isOverlapping(TimePlannerTask task) {
    DateTimeRange range1 = DateTimeRange(
        start: this.dateTime.dateTime,
        end: this
            .dateTime
            .dateTime
            .add(Duration(minutes: this.minutesDuration)));

    DateTimeRange range2 = DateTimeRange(
        start: task.dateTime.dateTime,
        end: task.dateTime.dateTime
            .add(Duration(minutes: task.minutesDuration)));

    return range1.start.isBefore(range2.end) &&
        range2.start.isBefore(range1.end);
  }

  TaskTreeNode generateTaskTree(List<TimePlannerTask> allTasks) {
    var sortedTasks = allTasks
      ..sort((a, b) => (a.dateTime.day + a.dateTime.minutes)
          .compareTo((b.dateTime.day + b.dateTime.minutes)));

    TaskTreeNode root = TaskTreeNode(null);

    if (sortedTasks.isEmpty) {
      return root;
    }

    void createNode(TimePlannerTask lastTask, List<TimePlannerTask> tasks) {
      if (tasks.isEmpty) {
        return;
      }

      var lastNode = root.add(lastTask);

      tasks.forEach((task) {
        if (lastTask.isOverlapping(task)) {
          root.remove(task);
          lastNode.add(task);
        } else {
          root.add(task);
        }
      });

      createNode(tasks.first, tasks.sublist(1));
    }

    var firstNode = TaskTreeNode(sortedTasks.first);
    root.add(firstNode.task!);

    createNode(firstNode.task!, sortedTasks.sublist(1));

    return root;
  }

  (double offset, double widthElement, double padding) findTaskPositionElements(
      List<TimePlannerTask> allTasks, TimePlannerTask currentTask) {
    final theTree = generateTaskTree(allTasks);
    final padding = 5;

    if (theTree.depth == 1) {
      return (0, 1, padding * 2);
    }

    final node = theTree.findTask(currentTask);
    if (node == null) {
      return (0, 1, 0);
    }

    final treeHeight = theTree.depth;
    double offset = 0;
    double taskPercentage = 0;
    final ancestors = node.ancesstors()..removeLast();

    for (var i = 0; i < ancestors.length; i++) {
      final ancestor = ancestors[i];
      final percentage = 1 / (ancestor.branchLength);
      offset += percentage;
    }

    final rootWidthPercentage = 1 / node.branchLength;
    if (node.branchLength == 1) {
      taskPercentage = 1;
    } else {
      taskPercentage = rootWidthPercentage;
    }

    return (offset, taskPercentage, padding * 2);
  }
}

class TaskTreeNode {
  final TimePlannerTask? task;
  final List<TaskTreeNode> children = [];
  final TaskTreeNode? parent;

  TaskTreeNode(this.task, {this.parent});

  TaskTreeNode add(TimePlannerTask task) {
    var existing = this.findTask(task);
    if (existing != null) return existing;
    var newNode = TaskTreeNode(task, parent: this);
    children.add(newNode);
    return newNode;
  }

  TaskTreeNode get segmentHead {
    return parent?.children.length != 1 ? this : parent!.segmentHead;
  }

  TaskTreeNode get segmentTail {
    return children.length != 1 ? this : children.first.segmentTail;
  }

  List<TaskTreeNode> get segment {
    final head = this.segmentHead;
    final tail = this.segmentTail;

    var segment = [head];

    while (segment.last != tail) {
      segment.add(segment.last.children.first);
    }

    return segment;
  }

  bool get isRoot => parent == null;

  int get generation {
    if (parent == null) {
      return 0;
    }

    return parent!.generation + 1;
  }

  void remove(TimePlannerTask task) {
    final node = this.findTask(task);
    if (node != null) children.remove(node);
  }

  bool operator ==(Object node) {
    if (node is TaskTreeNode == false) {
      return false;
    }
    return this.task?.child == (node as TaskTreeNode).task?.child;
  }

  @override
  int get hashCode {
    return this.task?.child.hashCode ?? 0;
  }

  int get depth {
    if (children.isEmpty) {
      return 1;
    }

    return children.map((child) => child.depth).reduce(max) + 1;
  }

  int get branchLength => depth + generation - 1;

  int heightOfChild(TaskTreeNode child) {
    if (child.children.isEmpty) {
      return 1;
    }

    return child.children.map((child) => child.depth).reduce(max) + 1;
  }

  List<TaskTreeNode> ancesstors() {
    if (parent == null) {
      return [];
    }

    return [parent!, ...parent!.ancesstors()];
  }

  TaskTreeNode? findTask(TimePlannerTask task) {
    if (this.task?.child == task.child) {
      return this;
    }

    return children
        .map((child) => child.findTask(task))
        .firstWhere((node) => node != null, orElse: () => null);
  }
}
