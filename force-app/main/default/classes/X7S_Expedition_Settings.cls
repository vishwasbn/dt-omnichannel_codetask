/*
 * Copyright (c) 2019. 7Summits Inc.
 */

/**
 * Created by francoiskorb on 2019-06-14.
 */

public with sharing class X7S_Expedition_Settings
{
	private static final String X7S_SETTINGS_NAME = 'Default';

	private static String emailTemplate;
	private static String emailProfile;

	public static String AnnouncementEmailTemplate
	{
		get
		{
			if (emailTemplate == null)
			{
				try
				{
					X7S_Expedition_Settings__mdt settings = [SELECT Announcement_Email_template__c FROM X7S_Expedition_Settings__mdt WHERE DeveloperName = :X7S_SETTINGS_NAME LIMIT 1];
					emailTemplate = settings.Announcement_Email_template__c;
				} catch (Exception ex)
				{
					emailTemplate = 'Announcement Email';
				}
			}

			return emailTemplate;
		}
	}

	public static String AnnouncementProfile
	{
		get
		{
			if (emailProfile == null)
			{
				try
				{
					X7S_Expedition_Settings__mdt settings = [SELECT Announcement_Email_Profile__c FROM X7S_Expedition_Settings__mdt WHERE DeveloperName = :X7S_SETTINGS_NAME LIMIT 1];
					emailProfile = settings.Announcement_Email_Profile__c;
				} catch (Exception ex)
				{
					emailProfile = Peak_TestConstants.COMMUNITY_PROFILE;
				}
			}

			return emailProfile;
		}
	}
}