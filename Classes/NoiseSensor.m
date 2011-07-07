//
//  NoiseSensor.m
//  senseApp
//
//  Created by Pim Nijdam on 3/1/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "NoiseSensor.h"
#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAssetReader.h>
#import <AVFoundation/AVAssetReaderOutput.h>
#import <CoreMedia/CMBlockBuffer.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioServices.h>

//Declare private methods using empty category
@interface NoiseSensor()
- (void) startRecording;
- (void) scheduleRecording;
- (void) incrementVolume;
@end

@implementation NoiseSensor
@synthesize sampleTimer;
@synthesize volumeTimer;

+ (NSString*) name {return @"noise_sensor";}
+ (NSString*) displayName {return @"noise";}
+ (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}


+ (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self displayName], @"display_name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"float", @"data_type",
			nil];
}

- (id) init {
	[super init];
	if (self) {
		
		//define audio category to allow mixing
		NSError *setCategoryError = nil;
		[[AVAudioSession sharedInstance]
		 setCategory: AVAudioSessionCategoryRecord
		 error: &setCategoryError];
		OSStatus propertySetError = 0;
		UInt32 allowMixing = true;
		propertySetError = AudioSessionSetProperty (
													kAudioSessionProperty_OverrideCategoryMixWithOthers,
													sizeof (allowMixing),
													&allowMixing
													);
		
		//set recording file
		NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																  NSUserDomainMask, YES) objectAtIndex:0];
		NSString* path = [rootPath stringByAppendingPathComponent:@"recording.wav"];
		NSURL* recording = [NSURL fileURLWithPath: path];
		
		/*
		NSDictionary* recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithInt:kAudioFormatAppleLossless], AVFormatIDKey,
										[NSNumber numberWithFloat:44100.0], AVSampleRateKey,
										[NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
										nil];
		 */
		NSError* error;
		audioRecorder = [[[AVAudioRecorder alloc] initWithURL:recording settings:nil error:&error] retain];
		if (nil == audioRecorder) {
			NSLog(@"Recorder could not be initialised. Error: %@", error);
		}
		audioRecorder.delegate = self;
		audioRecorder.meteringEnabled = YES;
		
		sampleInterval = 60;
		sampleDuration = 2;
		volumeSampleInterval = 0.2;
	}
	return self;
}

- (void)  scheduleRecording {
	self.sampleTimer = [NSTimer scheduledTimerWithTimeInterval:sampleInterval target:self selector:@selector(startRecording) userInfo:nil repeats:NO];
}

- (void) startRecording {
	NSError* error = nil;
	//try to activate the session
	[[AVAudioSession sharedInstance] setActive:YES error:&error];
	audioRecorder.delegate = self;
	BOOL started = [audioRecorder recordForDuration:sampleDuration];
	NSLog(@"recorder %@", started? @"started":@"failed to start");
	if (NO == started) {
		//try again later
		[self scheduleRecording];
		return;
	}
	volumeSum = 0;
	nrVolumeSamples = 0;
	self.volumeTimer = [NSTimer scheduledTimerWithTimeInterval:volumeSampleInterval target:self selector:@selector(incrementVolume) userInfo:nil repeats:YES];
}

- (void) incrementVolume {
	[audioRecorder updateMeters];
	volumeSum +=  pow(10, [audioRecorder averagePowerForChannel:0] / 20);
	++nrVolumeSamples;
}


- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"Enabling noise sensor (id=%d): %@", sensorId, enable ? @"yes":@"no");
	isEnabled = enable;
	if (enable) {
		if (NO==audioRecorder.recording) {
			[self startRecording];
		}
	} else {
		audioRecorder.delegate = nil;
		[audioRecorder stop];
		//cancel a scheduled recording
		[volumeTimer invalidate];
		self.volumeTimer = nil;
		//[sampleTimer invalidate];
		self.sampleTimer = nil;
	}
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)didSucceed {
	[volumeTimer invalidate];
	self.volumeTimer = nil;
	if (didSucceed && nrVolumeSamples > 0)	{
		NSLog(@"recorder finished succesfully");
		//take timestamp
		NSNumber* timestamp = [NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]];

		/*
		NSData* linearSamples = [NSData dataWithContentsOfURL:recorder.url];
		Byte* samples = (Byte*)[linearSamples bytes];
		NSInteger sum=0;
		NSInteger nrSamples = [linearSamples length];
		for (int i = 0; i<nrSamples;i+=2) {
			sum += (samples[i+1]<<8) | samples[i];
		}
		 */
		/*
		AVURLAsset *recording = [AVURLAsset URLAssetWithURL:recorder.url options:nil];
		AVAssetReader* recordingReader = [AVAssetReader assetReaderWithAsset:recording error:nil];
		AVAssetReaderOutput* output =
		[AVAssetReaderAudioMixOutput
		  assetReaderAudioMixOutputWithAudioTracks:recording.tracks
		 audioSettings: nil];
		[recordingReader addOutput: output];
		//process audio
		CMSampleBufferRef nextBuffer;
		NSInteger sum=0;
	
		while (NULL != (nextBuffer =[output copyNextSampleBuffer])) {
			size_t remaining, totalLength;
			char* data;
			OSStatus status = CMBlockBufferGetDataPointer (CMSampleBufferGetDataBuffer(nextBuffer),
												  0,
												  &remaining,
												  totalLength,
												  &data);
			length += remaining;
			while (remaining) {
				--remaining;
				sum += data[remaining];
			}
		}
		 */

		NSNumber* level = [NSNumber numberWithFloat:20 * log10(volumeSum / nrVolumeSamples)];
		NSLog(@"level: %@", level);
 
		//TODO: save file...
		[recorder deleteRecording];
	
		NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
											level, @"value",
											timestamp, @"date",
											nil];
	
		[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
	} else {
		NSLog(@"recorder finished unsuccesfully");
	}

	if (isEnabled) {
		[self scheduleRecording];
	}
}

-(void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder {
	NSLog(@"Noise sensor interrupted.");
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withFlags:(NSUInteger)flags {
	NSLog(@"recorder interruption ended");
	[recorder stop];
	[recorder deleteRecording];
	if (isEnabled) {
		//start a new recording
		[self startRecording];
	}
}

- (void) dealloc {
	NSLog(@"DEALLOCating noise sensor");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.isEnabled = NO;
	[audioRecorder release];
	
	[super dealloc];
}

@end
