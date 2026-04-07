const mongoose = require('mongoose');

const Task = require('../models/Task');
const { getProjectAccess } = require('./project.service');

const toObjectId = (value) => new mongoose.Types.ObjectId(value);

const startOfLocalDay = (date = new Date()) => {
  const start = new Date(date);
  start.setHours(0, 0, 0, 0);
  return start;
};

const endOfLocalDay = (date = new Date()) => {
  const end = new Date(date);
  end.setHours(23, 59, 59, 999);
  return end;
};

const toCountMap = (entries = []) =>
  entries.reduce(
    (accumulator, entry) => ({
      ...accumulator,
      [entry._id || 'unknown']: entry.count,
    }),
    {},
  );

const getProjectAnalyticsOverview = async (user, projectId) => {
  await getProjectAccess(user, projectId);

  const now = new Date();
  const todayStart = startOfLocalDay(now);
  const todayEnd = endOfLocalDay(now);
  // A single aggregation with $facet lets us compute several dashboard cards
  // in one database round trip.
  const [aggregate] = await Task.aggregate([
    {
      $match: {
        projectId: toObjectId(projectId),
      },
    },
    {
      $facet: {
        statusCounts: [
          {
            $group: {
              _id: '$status',
              count: { $sum: 1 },
            },
          },
        ],
        overview: [
          {
            $group: {
              _id: null,
              total: { $sum: 1 },
              completed: {
                $sum: {
                  $cond: [{ $eq: ['$status', 'done'] }, 1, 0],
                },
              },
            },
          },
        ],
        overdue: [
          {
            $match: {
              status: { $ne: 'done' },
              dueDate: { $lt: now },
            },
          },
          { $count: 'count' },
        ],
        dueToday: [
          {
            $match: {
              status: { $ne: 'done' },
              dueDate: { $gte: todayStart, $lte: todayEnd },
            },
          },
          { $count: 'count' },
        ],
        completionMetrics: [
          {
            $match: {
              status: 'done',
              completedAt: { $ne: null },
            },
          },
          {
            $project: {
              completionMinutes: {
                $divide: [{ $subtract: ['$completedAt', '$createdAt'] }, 60000],
              },
            },
          },
          {
            $group: {
              _id: null,
              averageCompletionMinutes: { $avg: '$completionMinutes' },
            },
          },
        ],
      },
    },
  ]);

  const statusCounts = toCountMap(aggregate?.statusCounts || []);
  const overview = aggregate?.overview?.[0] || { total: 0, completed: 0 };
  const completedCount = overview.completed || 0;
  const totalCount = overview.total || 0;

  return {
    projectId,
    generatedAt: now,
    totals: {
      total: totalCount,
      todo: statusCounts.todo || 0,
      inProgress: statusCounts.in_progress || 0,
      done: statusCounts.done || 0,
      overdue: aggregate?.overdue?.[0]?.count || 0,
      dueToday: aggregate?.dueToday?.[0]?.count || 0,
    },
    completion: {
      completedCount,
      completionRate: totalCount === 0 ? 0 : Number((completedCount / totalCount).toFixed(4)),
      averageCompletionMinutes:
        aggregate?.completionMetrics?.[0]?.averageCompletionMinutes !== undefined
          ? Number(
              aggregate.completionMetrics[0].averageCompletionMinutes.toFixed(2),
            )
          : null,
    },
  };
};

const getProjectAnalyticsWorkload = async (user, projectId) => {
  await getProjectAccess(user, projectId);

  // Workload analytics break tasks down by priority, assignee, and tag
  // so the frontend dashboard can stay simple and mostly read-only.
  const [aggregate] = await Task.aggregate([
    {
      $match: {
        projectId: toObjectId(projectId),
      },
    },
    {
      $facet: {
        priorities: [
          {
            $group: {
              _id: '$priority',
              taskCount: { $sum: 1 },
              openTaskCount: {
                $sum: {
                  $cond: [{ $ne: ['$status', 'done'] }, 1, 0],
                },
              },
              completedTaskCount: {
                $sum: {
                  $cond: [{ $eq: ['$status', 'done'] }, 1, 0],
                },
              },
            },
          },
          { $sort: { taskCount: -1, _id: 1 } },
        ],
        assignees: [
          {
            $project: {
              status: 1,
              assigneeIds: {
                $cond: [
                  { $gt: [{ $size: '$assigneeIds' }, 0] },
                  '$assigneeIds',
                  [null],
                ],
              },
            },
          },
          { $unwind: '$assigneeIds' },
          {
            $group: {
              _id: '$assigneeIds',
              taskCount: { $sum: 1 },
              openTaskCount: {
                $sum: {
                  $cond: [{ $ne: ['$status', 'done'] }, 1, 0],
                },
              },
              completedTaskCount: {
                $sum: {
                  $cond: [{ $eq: ['$status', 'done'] }, 1, 0],
                },
              },
            },
          },
          {
            $lookup: {
              from: 'users',
              localField: '_id',
              foreignField: '_id',
              as: 'user',
            },
          },
          {
            $project: {
              _id: 0,
              assigneeId: '$_id',
              label: {
                $ifNull: [{ $arrayElemAt: ['$user.username', 0] }, 'Unassigned'],
              },
              taskCount: 1,
              openTaskCount: 1,
              completedTaskCount: 1,
            },
          },
          { $sort: { taskCount: -1, label: 1 } },
        ],
        tags: [
          {
            $project: {
              status: 1,
              tagIds: {
                $cond: [
                  { $gt: [{ $size: '$tagIds' }, 0] },
                  '$tagIds',
                  [null],
                ],
              },
            },
          },
          { $unwind: '$tagIds' },
          {
            $group: {
              _id: '$tagIds',
              taskCount: { $sum: 1 },
              openTaskCount: {
                $sum: {
                  $cond: [{ $ne: ['$status', 'done'] }, 1, 0],
                },
              },
              completedTaskCount: {
                $sum: {
                  $cond: [{ $eq: ['$status', 'done'] }, 1, 0],
                },
              },
            },
          },
          {
            $lookup: {
              from: 'tags',
              localField: '_id',
              foreignField: '_id',
              as: 'tag',
            },
          },
          {
            $project: {
              _id: 0,
              tagId: '$_id',
              label: {
                $ifNull: [{ $arrayElemAt: ['$tag.name', 0] }, 'Untagged'],
              },
              color: { $ifNull: [{ $arrayElemAt: ['$tag.color', 0] }, null] },
              taskCount: 1,
              openTaskCount: 1,
              completedTaskCount: 1,
            },
          },
          { $sort: { taskCount: -1, label: 1 } },
        ],
      },
    },
  ]);

  return {
    projectId,
    generatedAt: new Date(),
    priorities: (aggregate?.priorities || []).map((entry) => ({
      priority: entry._id || 'unknown',
      taskCount: entry.taskCount,
      openTaskCount: entry.openTaskCount,
      completedTaskCount: entry.completedTaskCount,
    })),
    assignees: aggregate?.assignees || [],
    tags: aggregate?.tags || [],
  };
};

module.exports = {
  getProjectAnalyticsOverview,
  getProjectAnalyticsWorkload,
};
