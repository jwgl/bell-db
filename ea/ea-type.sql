create type ea.state as enum (
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

create type ea.event as enum (
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
