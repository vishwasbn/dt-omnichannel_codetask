/* Copyright © 2016-2017 7Summits, Inc. All rights reserved. */

trigger Peak_KnowledgeFileSharingTrigger on ContentDocumentLink (before insert) {
    Peak_KnowledgeFileSharingTriggerHelper.handleBeforeInsert(Trigger.new);
}