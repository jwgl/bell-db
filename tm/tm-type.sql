create type tm.state as enum (
    'CREATED',
    'SUBMITTED',
    'CHECKED',
    'REJECTED',
    'APPROVED',
    'CLOSED',
    'REVOKED',
    'PROGRESS',
    'FINISHED',
    'DELETED'
);

create type tm.event as enum (
    'CREATE',
    'UPDATE',
    'DELETE',
    'SUBMIT',
    'CANCEL',
    'ACCEPT',
    'REJECT',
    'REVIEW',
    'REVOKE',
    'CLOSE',
    'OPEN',
    'PROCESS',
    'FINISH'
);
