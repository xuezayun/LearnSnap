import 'home_snapshot.dart';

enum TaskCategory {
  pending,
  rejected,
  awaitingReview,
  completed,
}

class TaskListSection {
  const TaskListSection({
    required this.category,
    required this.title,
    required this.items,
  });

  final TaskCategory category;
  final String title;
  final List<TodayBoxItem> items;
}

TaskCategory categoryForBox(TodayBoxItem box) {
  if (!box.submitted) return TaskCategory.pending;
  if (box.checkinStatus == 'rejected') return TaskCategory.rejected;
  if (box.canRevise) return TaskCategory.awaitingReview;
  return TaskCategory.completed;
}

String titleForCategory(TaskCategory category) {
  switch (category) {
    case TaskCategory.pending:
      return '待打卡';
    case TaskCategory.rejected:
      return '已驳回 · 可修订';
    case TaskCategory.awaitingReview:
      return '已提交 · 待家长审核';
    case TaskCategory.completed:
      return '家长已审核';
  }
}

List<TaskListSection> groupTasksByStatus(List<TodayBoxItem> boxes) {
  final order = [
    TaskCategory.pending,
    TaskCategory.awaitingReview,
    TaskCategory.rejected,
    TaskCategory.completed,
  ];
  final grouped = <TaskCategory, List<TodayBoxItem>>{};
  for (final box in boxes) {
    final category = categoryForBox(box);
    grouped.putIfAbsent(category, () => []).add(box);
  }
  return order
      .where((category) => grouped[category]?.isNotEmpty ?? false)
      .map(
        (category) => TaskListSection(
          category: category,
          title: titleForCategory(category),
          items: grouped[category]!,
        ),
      )
      .toList();
}
