const mongoose = require('mongoose');
const request = require('supertest');
const { MongoMemoryReplSet } = require('mongodb-memory-server');

process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret';

const app = require('../src/app');
const Reminder = require('../src/models/Reminder');
const User = require('../src/models/User');
const {
  createReminder,
  processDueReminders,
} = require('../src/services/reminder.service');

jest.setTimeout(120000);

let mongoServer;

const registerAndLogin = async ({ username, password, email }) => {
  const registerResponse = await request(app).post('/api/auth/register').send({
    username,
    password,
    email,
  });

  expect(registerResponse.status).toBe(201);

  const loginResponse = await request(app).post('/api/auth/login').send({
    username,
    password,
  });

  expect(loginResponse.status).toBe(200);

  return {
    token: loginResponse.body.token,
    user: loginResponse.body.user,
  };
};

const authHeader = (token) => ({
  Authorization: `Bearer ${token}`,
});

const clearDatabase = async () => {
  const collections = Object.values(mongoose.connection.collections);
  for (const collection of collections) {
    await collection.deleteMany({});
  }
};

beforeAll(async () => {
  mongoServer = await MongoMemoryReplSet.create({
    replSet: { count: 1 },
  });

  await mongoose.connect(mongoServer.getUri(), {
    dbName: 'shizuki-test',
  });

  await Promise.all(
    Object.values(mongoose.models).map((model) =>
      model.init().catch(() => undefined),
    ),
  );
});

afterEach(async () => {
  await clearDatabase();
});

afterAll(async () => {
  if (mongoServer) {
    const originalWarn = console.warn;
    console.warn = (...args) => {
      const [firstArg] = args;
      if (
        firstArg &&
        typeof firstArg.message === 'string' &&
        firstArg.message.includes('ECONNRESET')
      ) {
        return;
      }

      originalWarn(...args);
    };

    try {
      await mongoServer.stop();
    } finally {
      console.warn = originalWarn;
    }
  }
  await mongoose.disconnect();
});

test('task workflow, checklist activity, and analytics endpoints work end to end', async () => {
  const owner = await registerAndLogin({
    username: 'owner_user',
    password: 'Password123!',
    email: 'owner@example.com',
  });
  const viewer = await registerAndLogin({
    username: 'viewer_user',
    password: 'Password123!',
    email: 'viewer@example.com',
  });
  const outsider = await registerAndLogin({
    username: 'outsider_user',
    password: 'Password123!',
    email: 'outsider@example.com',
  });

  const createProjectResponse = await request(app)
    .post('/api/projects')
    .set(authHeader(owner.token))
    .send({
      name: 'Workflow Project',
      description: 'Project used for workflow analytics tests',
    });

  expect(createProjectResponse.status).toBe(201);
  const projectId = createProjectResponse.body.data._id;

  const addViewerResponse = await request(app)
    .post(`/api/projects/${projectId}/members`)
    .set(authHeader(owner.token))
    .send({
      userId: viewer.user.id,
      role: 'viewer',
    });

  expect(addViewerResponse.status).toBe(201);

  const listTagsResponse = await request(app)
    .get(`/api/projects/${projectId}/tags`)
    .set(authHeader(owner.token));

  expect(listTagsResponse.status).toBe(200);
  const tagId = listTagsResponse.body.data[0]._id;

  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const todayEnd = new Date();
  todayEnd.setHours(23, 59, 59, 999);

  const workflowTaskResponse = await request(app)
    .post('/api/tasks')
    .set(authHeader(owner.token))
    .send({
      projectId,
      title: 'Workflow task',
      priority: 'high',
      dueDate: tomorrow.toISOString(),
      estimatedMinutes: 120,
      assigneeIds: [viewer.user.id],
      tagIds: [tagId],
    });

  expect(workflowTaskResponse.status).toBe(201);
  const workflowTaskId = workflowTaskResponse.body.data._id;

  const moveToInProgressResponse = await request(app)
    .patch(`/api/tasks/${workflowTaskId}`)
    .set(authHeader(owner.token))
    .send({ status: 'in_progress' });

  expect(moveToInProgressResponse.status).toBe(200);
  expect(moveToInProgressResponse.body.data.startedAt).toBeTruthy();
  expect(moveToInProgressResponse.body.data.completedAt).toBeNull();
  const firstStartedAt = moveToInProgressResponse.body.data.startedAt;

  const moveToDoneResponse = await request(app)
    .patch(`/api/tasks/${workflowTaskId}`)
    .set(authHeader(owner.token))
    .send({ status: 'done' });

  expect(moveToDoneResponse.status).toBe(200);
  expect(moveToDoneResponse.body.data.completedAt).toBeTruthy();

  const reopenTaskResponse = await request(app)
    .patch(`/api/tasks/${workflowTaskId}`)
    .set(authHeader(owner.token))
    .send({ status: 'todo' });

  expect(reopenTaskResponse.status).toBe(200);
  expect(reopenTaskResponse.body.data.completedAt).toBeNull();
  expect(reopenTaskResponse.body.data.startedAt).toBe(firstStartedAt);

  const finishTaskAgainResponse = await request(app)
    .patch(`/api/tasks/${workflowTaskId}`)
    .set(authHeader(owner.token))
    .send({ status: 'done' });

  expect(finishTaskAgainResponse.status).toBe(200);
  expect(finishTaskAgainResponse.body.data.completedAt).toBeTruthy();

  const collaborationTaskResponse = await request(app)
    .post('/api/tasks')
    .set(authHeader(owner.token))
    .send({
      projectId,
      title: 'Collaboration task',
      priority: 'medium',
      dueDate: todayEnd.toISOString(),
      estimatedMinutes: 60,
    });

  expect(collaborationTaskResponse.status).toBe(201);
  const collaborationTaskId = collaborationTaskResponse.body.data._id;

  const updateCollaborationTaskResponse = await request(app)
    .patch(`/api/tasks/${collaborationTaskId}`)
    .set(authHeader(owner.token))
    .send({
      assigneeIds: [viewer.user.id],
      tagIds: [tagId],
    });

  expect(updateCollaborationTaskResponse.status).toBe(200);

  const overdueTaskResponse = await request(app)
    .post('/api/tasks')
    .set(authHeader(owner.token))
    .send({
      projectId,
      title: 'Overdue task',
      priority: 'low',
      dueDate: yesterday.toISOString(),
      estimatedMinutes: 30,
    });

  expect(overdueTaskResponse.status).toBe(201);

  const createChecklistItemResponse = await request(app)
    .post(`/api/tasks/${collaborationTaskId}/checklist`)
    .set(authHeader(owner.token))
    .send({
      content: 'Prepare summary',
    });

  expect(createChecklistItemResponse.status).toBe(201);
  const checklistItemId = createChecklistItemResponse.body.data._id;

  const viewerCannotEditChecklistResponse = await request(app)
    .patch(`/api/tasks/${collaborationTaskId}/checklist/${checklistItemId}`)
    .set(authHeader(viewer.token))
    .send({
      isCompleted: true,
    });

  expect(viewerCannotEditChecklistResponse.status).toBe(403);

  const completeChecklistItemResponse = await request(app)
    .patch(`/api/tasks/${collaborationTaskId}/checklist/${checklistItemId}`)
    .set(authHeader(owner.token))
    .send({
      isCompleted: true,
    });

  expect(completeChecklistItemResponse.status).toBe(200);
  expect(completeChecklistItemResponse.body.data.isCompleted).toBe(true);
  expect(completeChecklistItemResponse.body.data.completedAt).toBeTruthy();

  const createCommentResponse = await request(app)
    .post(`/api/tasks/${collaborationTaskId}/comments`)
    .set(authHeader(owner.token))
    .send({
      content: 'Comment for activity tracking',
    });

  expect(createCommentResponse.status).toBe(201);

  const workflowActivityResponse = await request(app)
    .get(`/api/tasks/${workflowTaskId}/activity`)
    .set(authHeader(owner.token));

  expect(workflowActivityResponse.status).toBe(200);
  expect(
    workflowActivityResponse.body.data.some(
      (entry) => entry.type === 'task.status_changed',
    ),
  ).toBe(true);

  const collaborationActivityResponse = await request(app)
    .get(`/api/tasks/${collaborationTaskId}/activity`)
    .set(authHeader(owner.token));

  expect(collaborationActivityResponse.status).toBe(200);
  expect(
    collaborationActivityResponse.body.data.some(
      (entry) => entry.type === 'task.assignees_changed',
    ),
  ).toBe(true);
  expect(
    collaborationActivityResponse.body.data.some(
      (entry) => entry.type === 'task.tags_changed',
    ),
  ).toBe(true);
  expect(
    collaborationActivityResponse.body.data.some(
      (entry) => entry.type === 'checklist.completed',
    ),
  ).toBe(true);
  expect(
    collaborationActivityResponse.body.data.some(
      (entry) => entry.type === 'comment.created',
    ),
  ).toBe(true);

  const analyticsOverviewResponse = await request(app)
    .get(`/api/projects/${projectId}/analytics/overview`)
    .set(authHeader(owner.token));

  expect(analyticsOverviewResponse.status).toBe(200);
  expect(analyticsOverviewResponse.body.data.totals.total).toBe(3);
  expect(analyticsOverviewResponse.body.data.totals.todo).toBe(2);
  expect(analyticsOverviewResponse.body.data.totals.done).toBe(1);
  expect(analyticsOverviewResponse.body.data.totals.overdue).toBe(1);
  expect(analyticsOverviewResponse.body.data.totals.dueToday).toBe(1);
  expect(analyticsOverviewResponse.body.data.completion.completedCount).toBe(1);
  expect(analyticsOverviewResponse.body.data.completion.completionRate).toBeCloseTo(
    1 / 3,
    4,
  );

  const analyticsWorkloadResponse = await request(app)
    .get(`/api/projects/${projectId}/analytics/workload`)
    .set(authHeader(owner.token));

  expect(analyticsWorkloadResponse.status).toBe(200);
  expect(
    analyticsWorkloadResponse.body.data.priorities.find(
      (entry) => entry.priority === 'high',
    ).taskCount,
  ).toBe(1);
  expect(
    analyticsWorkloadResponse.body.data.assignees.find(
      (entry) => entry.label === 'viewer_user',
    ).taskCount,
  ).toBe(2);
  expect(
    analyticsWorkloadResponse.body.data.tags.find(
      (entry) => entry.label === 'General',
    ).taskCount,
  ).toBe(2);

  const outsiderAnalyticsResponse = await request(app)
    .get(`/api/projects/${projectId}/analytics/overview`)
    .set(authHeader(outsider.token));

  expect(outsiderAnalyticsResponse.status).toBe(403);
});

test('a single uploaded file can be attached to multiple tasks without being deleted from the other task', async () => {
  const owner = await registerAndLogin({
    username: 'shared_file_owner',
    password: 'Password123!',
    email: 'shared-file-owner@example.com',
  });

  const createProjectResponse = await request(app)
    .post('/api/projects')
    .set(authHeader(owner.token))
    .send({
      name: 'Shared File Project',
      description: 'Project used for shared task file tests',
    });

  expect(createProjectResponse.status).toBe(201);
  const projectId = createProjectResponse.body.data._id;

  const uploadFileResponse = await request(app)
    .post('/api/files')
    .set(authHeader(owner.token))
    .attach('file', Buffer.from('shared file content'), {
      filename: 'shared-spec.pdf',
      contentType: 'application/pdf',
    });

  expect(uploadFileResponse.status).toBe(201);
  const fileId = uploadFileResponse.body.data._id;

  const firstTaskResponse = await request(app)
    .post('/api/tasks')
    .set(authHeader(owner.token))
    .send({
      projectId,
      title: 'Task using shared file',
      fileIds: [fileId],
    });

  expect(firstTaskResponse.status).toBe(201);
  const firstTaskId = firstTaskResponse.body.data._id;
  expect(firstTaskResponse.body.data.fileIds).toHaveLength(1);

  const secondTaskResponse = await request(app)
    .post('/api/tasks')
    .set(authHeader(owner.token))
    .send({
      projectId,
      title: 'Second task using the same file',
      fileIds: [fileId],
    });

  expect(secondTaskResponse.status).toBe(201);
  const secondTaskId = secondTaskResponse.body.data._id;
  expect(secondTaskResponse.body.data.fileIds).toHaveLength(1);

  const listFilesAfterAttachResponse = await request(app)
    .get('/api/files')
    .set(authHeader(owner.token));

  expect(listFilesAfterAttachResponse.status).toBe(200);
  const sharedFileAfterAttach = listFilesAfterAttachResponse.body.data.find(
    (file) => file._id === fileId,
  );
  expect(sharedFileAfterAttach).toBeTruthy();
  expect(sharedFileAfterAttach.ownerType).toBe('unassigned');
  expect(sharedFileAfterAttach.taskIds).toHaveLength(2);

  const deleteFirstTaskResponse = await request(app)
    .delete(`/api/tasks/${firstTaskId}`)
    .set(authHeader(owner.token));

  expect(deleteFirstTaskResponse.status).toBe(200);

  const listFilesAfterDeleteResponse = await request(app)
    .get('/api/files')
    .set(authHeader(owner.token));

  expect(listFilesAfterDeleteResponse.status).toBe(200);
  const sharedFileAfterTaskDelete = listFilesAfterDeleteResponse.body.data.find(
    (file) => file._id === fileId,
  );
  expect(sharedFileAfterTaskDelete).toBeTruthy();
  expect(sharedFileAfterTaskDelete.taskIds).toHaveLength(1);

  const secondTaskDetailResponse = await request(app)
    .get(`/api/tasks/${secondTaskId}`)
    .set(authHeader(owner.token));

  expect(secondTaskDetailResponse.status).toBe(200);
  expect(secondTaskDetailResponse.body.data.fileIds).toHaveLength(1);
  expect(secondTaskDetailResponse.body.data.fileIds[0]._id).toBe(fileId);

  const deleteFileResponse = await request(app)
    .delete(`/api/files/${fileId}`)
    .set(authHeader(owner.token));

  expect(deleteFileResponse.status).toBe(200);

  const secondTaskAfterFileDeleteResponse = await request(app)
    .get(`/api/tasks/${secondTaskId}`)
    .set(authHeader(owner.token));

  expect(secondTaskAfterFileDeleteResponse.status).toBe(200);
  expect(secondTaskAfterFileDeleteResponse.body.data.fileIds).toHaveLength(0);
});

test('recurring reminders advance instead of auto-completing', async () => {
  const recurringUser = await User.create({
    username: 'reminder_user',
    email: 'reminder@example.com',
  });

  const scheduledTime = new Date(Date.now() - 60 * 1000);
  const reminder = await createReminder({
    userId: recurringUser._id,
    payload: {
      message: 'Standup reminder',
      scheduledTime,
      daysOfWeek: ['mon', 'wed'],
    },
  });

  const emit = jest.fn();
  const io = {
    to: jest.fn(() => ({
      emit,
    })),
  };

  const processedCount = await processDueReminders(io);
  expect(processedCount).toBe(1);

  const updatedReminder = await Reminder.findById(reminder._id);
  expect(updatedReminder).not.toBeNull();
  expect(updatedReminder.isCompleted).toBe(false);
  expect(updatedReminder.scheduledTime.getTime()).toBeGreaterThan(Date.now());
  expect(updatedReminder.daysOfWeek).toEqual(['monday', 'wednesday']);
  expect(io.to).toHaveBeenCalledWith(recurringUser._id.toString());
  expect(emit).toHaveBeenCalledWith('system:alert', {
    message: 'Standup reminder',
  });
});
