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
    // String key = dateTime.day.toString();
    String key =
        "${dateTime.dateTime.year}${dateTime.dateTime.month}${dateTime.dateTime.day}";
    this._allTasksInTheDay = allTasks[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final (offset, widthPercentage, padding) =
        findTaskPositionElements(_allTasksInTheDay, this);
    double width = ((config.cellWidth!.toDouble() ?? padding) - padding) *
        widthPercentage.toDouble();
    double dayOffset = offset * (config.cellWidth!.toDouble() ?? 0);
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
    return (range1.start.isBefore(range2.end) &&
        range2.start.isBefore(range1.end));
  }

  /* Calculation Implementation*/
  bool checkTaskExist(
      {required List resultList, required TimePlannerTask task}) {
    for (var data in resultList) {
      if (data is List) {
        final subCheck = checkTaskExist(resultList: data, task: task);
        if (subCheck == true) {
          return true;
        }
      } else {
        final savedTask = data as TimePlannerTask;
        if (savedTask == task) {
          return true;
        }
      }
    }
    return false;
  }

  bool checkIfListContainsSublit(
      List<List<TimePlannerTask>> list, List<TimePlannerTask> subList) {
    bool isContain = false;
    for (var listOfTask in list) {
      List<bool> subContain = [];
      if (listOfTask.length != subList.length) {
        continue;
      }
      for (var element in subList) {
        if (listOfTask.contains(element) == true) {
          subContain.add(true);
        }
      }
      if (subContain.length == subList.length) {
        return true;
      }
    }
    return isContain;
  }

  List<List<TimePlannerTask>> addToTeam(List<TimePlannerTask> originData) {
    List<List<TimePlannerTask>> output = [];
    List<TimePlannerTask> copyData = [];
    copyData.addAll(originData);
    for (var originData in originData) {
      for (var compairData in copyData) {
        if (originData != compairData) {
          if (originData.isOverlapping(compairData)) {
            final temp = [originData, compairData];
            temp.sort(
              (a, b) {
                if (a.dateTime.dateTime.isAtSameMomentAs(b.dateTime.dateTime) ==
                    false) {
                  return a.dateTime.dateTime.compareTo(b.dateTime.dateTime);
                }
                return a.minutesDuration.compareTo(b.minutesDuration);
              },
            );
            if (checkIfListContainsSublit(output, temp) == false) {
              output.add(temp);
            }
          }
        }
      }
      if (checkTaskExist(resultList: output, task: originData) == false) {
        output.add([originData]);
      }
    }
    return output;
  }

  List<List<TimePlannerTask>> _customMerge(List<List<TimePlannerTask>> input) {
    List<List<TimePlannerTask>> output = [];
    for (var i = 0; i < input.length; i++) {
      if (i == input.length - 1) {
        output = _checkFirstOrLastcontains(output, input[i]);
        output.add(input[i]);
        break;
      }
      final sublistA = input[i];
      List<TimePlannerTask> sublistB = [];

      if (i + 1 <= input.length - 1) {
        sublistB = input[i + 1];
      } else {
        print('Check Point');
      }

      if (sublistB.isNotEmpty && sublistA.last == sublistB.first) {
        final merged = _mergeLists([sublistA, sublistB]);
        output.add(merged);
        continue;
      }

      if (sublistB.isNotEmpty && sublistA.first == sublistB.first) {
        final lastComponent = [sublistA.last, sublistB.last];
        if (input.contains(lastComponent)) {
          final merged = _mergeLists([sublistA, sublistB]);
          output.add(merged);
          continue;
        }
      }
      if (sublistB.isNotEmpty && _checkIfContains(sublistA, sublistB)) {
        output.add(sublistA);
        continue;
      }
      if (sublistB.isNotEmpty && _checkIfContains(sublistB, sublistA)) {
        output.add(sublistB);
        continue;
      }

      output = _checkFirstOrLastcontains(output, sublistA);

      if (_checkIfListContains(output, sublistA) == false) {
        output.add(sublistA);
        continue;
      }

      // if (output.isEmpty) {
      output.add(sublistA);
      // }
    }
    if (_checkIfListsAreEqual(input, output)) {
      return _removeRedundantElements(output);
    }
    return _customMerge(_removeRedundantElements(output));
  }

  bool _checkIfListContains(
      List<List<TimePlannerTask>> allList, List<TimePlannerTask> listB) {
    //检查是否包含了另一个数组的元素
    for (List<TimePlannerTask> listA in allList) {
      for (var element in listB) {
        if (listA.contains(element)) {
          return true;
        }
      }
    }
    return false;
  }

  List<List<TimePlannerTask>> _checkFirstOrLastcontains(
      List<List<TimePlannerTask>> allList, List<TimePlannerTask> listB) {
    if (allList.isEmpty) {
      return [];
    }

    //如果第一个和最后一个被同时包含了，那么应该被Merge
    //[0, 1, 2, 3], [0, 3, 4] 就应该被Merge成[0, 1, 2, 3, 4]
    for (var listA in allList) {
      // final first = listA.first;
      final last = listA.last;

      if (listB.contains(last)) {
        for (var element in listB) {
          if (!listA.contains(element)) {
            listA.add(element);
          }
        }
      }
    }
    return allList;
  }

  List<TimePlannerTask> _mergeLists(List<List<TimePlannerTask>> input) {
    //简单的将两个数组合成为一个
    List<TimePlannerTask> output = [];
    for (var subList in input) {
      for (var item in subList) {
        if (!output.contains(item)) {
          output.add(item);
        }
      }
    }
    return output;
  }

  bool _checkIfContains(
      List<TimePlannerTask> listA, List<TimePlannerTask> listB) {
    // 检查List A 中是否包含了List B
    for (TimePlannerTask element in listB) {
      if (!listA.contains(element)) {
        return false;
      }
    }
    return true;
  }

  bool _checkIfListsAreEqual(
      List<List<TimePlannerTask>> listA, List<List<TimePlannerTask>> listB) {
    if (listA.length != listB.length) {
      return false;
    }

    for (int i = 0; i < listA.length; i++) {
      if (listA[i].length != listB[i].length) {
        return false;
      }

      for (int j = 0; j < listA[i].length; j++) {
        if (listA[i][j] != listB[i][j]) {
          return false;
        }
      }
    }

    return true;
  }

  List<List<TimePlannerTask>> _removeRedundantElements(
      List<List<TimePlannerTask>> list) {
    List<List<TimePlannerTask>> result = [];

    for (List<TimePlannerTask> sublist in list) {
      bool isRedundant = false;

      for (List<TimePlannerTask> existingSublist in result) {
        if (sublist.length == existingSublist.length &&
            sublist.every((element) => existingSublist.contains(element))) {
          isRedundant = true;
          break;
        }
      }

      if (!isRedundant) {
        result.add(sublist);
      }
    }

    return result;
  }

  List<List<TimePlannerTask>> _removeSublistsWithLastElementContained(
      List<List<TimePlannerTask>> list) {
    //移除因为重复包含最后一个元素的集合。
    List<List<TimePlannerTask>> result = [];

    for (List<TimePlannerTask> sublist in list) {
      bool isContained = false;

      for (List<TimePlannerTask> existingSublist in result) {
        if (existingSublist.contains(sublist.last)) {
          isContained = true;
          break;
        }
      }

      if (!isContained) {
        result.add(sublist);
      }
    }

    return result;
  }

  ({int outIndex, int index, int length}) calculateTakenSpace(
      List<List<dynamic>> input, dynamic inputData) {
    int maxLength = 0;
    int finalIndex = 0;
    int outIndex = 0;
    for (var element in input) {
      if (element.contains(inputData)) {
        final index = element.indexOf(inputData);
        final outlayoutIndex = input.indexOf(element);
        if (element.length > maxLength) {
          maxLength = element.length;
          finalIndex = index;
          outIndex = outlayoutIndex;
        }
      }
    }
    return (outIndex: outIndex, index: finalIndex, length: maxLength);
  }

  double calcualteDiffWidth(List<int> diffLengthList, int currentLength) {
    double takenSpace = 0;
    double diffOffset = 0;
    for (var diff in diffLengthList) {
      diffOffset += 1 / diff;
    }
    takenSpace = (1 - diffOffset) / (currentLength - diffLengthList.length);
    return takenSpace;
  }

/*Merge End*/
  Map<int, ({int outIndex, int index, int length})> taskTakenMap = Map();
  List<List<TimePlannerTask>> dataList = [];
  ({double offset, double takenSpace}) sortAndGeneratePositionInfo(
      List<TimePlannerTask> allTasks, TimePlannerTask currentTask) {
    if (taskTakenMap[currentTask.hashCode] == null) {
      taskTakenMap.clear();
      dataList.clear();
      allTasks.sort(
        (a, b) {
          if (a.dateTime.dateTime.isAtSameMomentAs(b.dateTime.dateTime) ==
              false) {
            return a.dateTime.dateTime.compareTo(b.dateTime.dateTime);
          }
          return a.minutesDuration.compareTo(b.minutesDuration);
        },
      );
      final outPut = addToTeam(allTasks);
      final mergedOutPut = _customMerge(outPut);
      dataList = _removeSublistsWithLastElementContained(mergedOutPut);
      // print('Input: ${outPut}');
      // print('First Merge: ${mergedOutPut}');
      // print('Final Result: ${dataList}');

      for (var element in allTasks) {
        final positionInfo = calculateTakenSpace(dataList, element);
        taskTakenMap[element.hashCode] = positionInfo;
      }
    }
    final positionInfo = taskTakenMap[currentTask.hashCode];
    final outIndex = positionInfo?.outIndex ?? 0;
    final currentIndex = positionInfo?.index ?? 0;
    final currentLength = positionInfo?.length ?? 1;
    final group = dataList[outIndex];

    double offset = 0;
    List<int> diffLength = [];
    for (var i = 0; i < group.length; i++) {
      if (i >= currentIndex) {
        break;
      }
      final data = group[i];
      final hashKey = data.hashCode;
      final savedInfo = taskTakenMap[hashKey];
      final savedLength = savedInfo?.length ?? 1;
      if (savedLength != group.length) {
        diffLength.add(savedLength);
      } else {
        if (diffLength.length > 0) {
          offset += calcualteDiffWidth(diffLength, currentLength);
          continue;
        }
      }

      offset += 1 / savedLength;
    }
    double takenSpace = 1 / currentLength;
    if (diffLength.length > 0) {
      takenSpace = calcualteDiffWidth(diffLength, currentLength);
    }
    return (offset: offset, takenSpace: takenSpace);
  }

  (double offset, double widthElement, double padding) findTaskPositionElements(
      List<TimePlannerTask> allTasks, TimePlannerTask currentTask) {
    final padding = 5;
    if (allTasks.length <= 1) {
      return (0, 1, padding * 2);
    }
    final output = sortAndGeneratePositionInfo(allTasks, currentTask);
    double offset = output.offset;
    double taskPercentage = output.takenSpace;

    return (offset, taskPercentage, padding * 2);
  }
}
