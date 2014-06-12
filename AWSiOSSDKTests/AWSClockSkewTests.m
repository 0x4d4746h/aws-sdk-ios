/*
 * Copyright 2010-2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#if AWS_TEST_CLOCK_SKEW

#import <XCTest/XCTest.h>
#import "AWSCore.h"
#import "S3.h"
#import "SimpleDB.h"
#import "DynamoDB.h"
#import "SQS.h"
#import "SNS.h"
#import "CloudWatch.h"
#import "SES.h"
#import "EC2.h"
#import "AutoScaling.h"
#import "ElasticLoadBalancing.h"

@import ObjectiveC.runtime;


@interface AWSClockSkewTests : XCTestCase

@end

@implementation AWSClockSkewTests

Method _originalDateMethod;
Method _mockDateMethod;
static char mockDateKey;

- (void)setUp
{
    [super setUp];
    
    // Start by having the mock return the test startup date
    [self setMockDate:[NSDate date]];
    
    // Save these as instance variables so test teardown can swap the implementation back
    _originalDateMethod = class_getClassMethod([NSDate class], @selector(date));
    _mockDateMethod = class_getInstanceMethod([self class], @selector(mockDateSwizzle));
    method_exchangeImplementations(_originalDateMethod, _mockDateMethod);
   
    //make sure current runTimeClockSkew is 0
    [NSDate az_setRuntimeClockSkew:0];
   

}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    // Revert the swizzle
    method_exchangeImplementations(_mockDateMethod, _originalDateMethod);
    //reset RunTimeClockSkew
    [NSDate az_setRuntimeClockSkew:0];
}

// Mock Method, replaces [NSDate date]
-(NSDate *)mockDateSwizzle {
    return objc_getAssociatedObject([NSDate class], &mockDateKey);
}

// Convenience method so tests can set want they want [NSDate date] to return
-(void)setMockDate:(NSDate *)aMockDate {
    objc_setAssociatedObject([NSDate class], &mockDateKey, aMockDate, OBJC_ASSOCIATION_RETAIN);
}

// S3 Test
-(void)testClockSkewS3
{
    XCTAssertFalse([NSDate az_getRuntimeClockSkew], @"current RunTimeClockSkew is not zero!");
    [self setMockDate:[NSDate dateWithTimeIntervalSince1970:3600]];
   
    AWSS3 *s3 = [AWSS3 defaultS3];
    XCTAssertNotNil(s3);
    
    [[[s3 listBuckets:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error, @"The request failed. error: [%@]", task.error);
        XCTAssertTrue([task.result isKindOfClass:[AWSS3ListBucketsOutput class]],@"The response object is not a class of [%@]", NSStringFromClass([AWSS3ListBucketsOutput class]));

        return nil;
    }] waitUntilFinished];
   
}

//SimpleDB Tests
-(void)testClockSkewSimpleDB
{
    XCTAssertFalse([NSDate az_getRuntimeClockSkew], @"current RunTimeClockSkew is not zero!");
    [self setMockDate:[NSDate dateWithTimeIntervalSince1970:3600]];
    
    AWSSimpleDB *sdb = [AWSSimpleDB defaultSimpleDB];
    
    AWSSimpleDBListDomainsRequest *listDomainsRequest = [AWSSimpleDBListDomainsRequest new];
    [[[sdb listDomains:listDomainsRequest] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            XCTFail(@"Error: [%@]", task.error);
        }
        
        if (task.result) {
            AWSSimpleDBListDomainsResult *listDomainsResult = task.result;
            XCTAssertNotNil(listDomainsResult.domainNames, @" doemainNames Array should not be nil.");
            AZLogDebug(@"[%@]", listDomainsResult);
        }
        
        return nil;
    }] waitUntilFinished];
}

//DynamoDB Test
-(void)testClockSkewDynamoDB
{
    XCTAssertFalse([NSDate az_getRuntimeClockSkew], @"current RunTimeClockSkew is not zero!");
    [self setMockDate:[NSDate dateWithTimeIntervalSince1970:3600]];
    
    AWSDynamoDB *dynamoDB = [AWSDynamoDB defaultDynamoDB];
    
    AWSDynamoDBListTablesInput *listTablesInput = [AWSDynamoDBListTablesInput new];
    
    [[[dynamoDB listTables:listTablesInput
       ] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            XCTFail(@"The request failed. error: [%@]", task.error);
        } else {
            AWSDynamoDBListTablesOutput *listTableOutput = task.result;
            XCTAssertNotNil(listTableOutput, @"AWSDynamoDBListTablesOutput should not be nil");
        }
        
        return nil;
    }] waitUntilFinished];
}

//SQS Test
-(void)testClockSkewSQS
{
    XCTAssertFalse([NSDate az_getRuntimeClockSkew], @"current RunTimeClockSkew is not zero!");
    [self setMockDate:[NSDate dateWithTimeIntervalSince1970:3600]];
    
    AWSSQS *sqs = [AWSSQS defaultSQS];
    
    AWSSQSListQueuesRequest *listQueuesRequest = [AWSSQSListQueuesRequest new];
    [[[sqs listQueues:listQueuesRequest] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            XCTFail(@"Error: [%@]", task.error);
        }
        
        if (task.result) {
            AWSSQSListQueuesResult *listQueuesResult = task.result;
            AZLogDebug(@"[%@]", listQueuesResult);
            XCTAssertNotNil(listQueuesResult.queueUrls);
        }
        
        return nil;
    }] waitUntilFinished];
    
}

//SNS Test
-(void)testClockSkewSNS
{
    XCTAssertFalse([NSDate az_getRuntimeClockSkew], @"current RunTimeClockSkew is not zero!");
    [self setMockDate:[NSDate dateWithTimeIntervalSince1970:3600]];
    
    AWSSNS *sns = [AWSSNS defaultSNS];
    
    AWSSNSListTopicsInput *listTopicsInput = [AWSSNSListTopicsInput new];
    [[[sns listTopics:listTopicsInput] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            XCTFail(@"Error: [%@]", task.error);
        }
        
        if (task.result) {
            XCTAssertTrue([task.result isKindOfClass:[AWSSNSListTopicsResponse class]]);
            AWSSNSListTopicsResponse *listTopicsResponse = task.result;
            XCTAssertTrue([listTopicsResponse.topics isKindOfClass:[NSArray class]]);
        }
        
        return nil;
    }] waitUntilFinished];
}

//CloudWatch Test
-(void)testClockSkewCW
{
    XCTAssertFalse([NSDate az_getRuntimeClockSkew], @"current RunTimeClockSkew is not zero!");
    [self setMockDate:[NSDate dateWithTimeIntervalSince1970:3600]];
    
    AWSCloudWatch *cloudWatch = [AWSCloudWatch defaultCloudWatch];
    
    [[[cloudWatch listHostInfo:nil] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            XCTFail(@"Error: [%@]", task.error);
        }
        
        if (task.result) {
            XCTAssertTrue([task.result isKindOfClass:[AWSCloudWatchListHostInfoOutput class]]);
            AWSCloudWatchListHostInfoOutput *listHostInfoOutput = task.result;
            XCTAssertNotNil(listHostInfoOutput.hostName);
        }
        
        return nil;
    }] waitUntilFinished];
}

//SES Test
-(void)testClockSkewSES
{
    XCTAssertFalse([NSDate az_getRuntimeClockSkew], @"current RunTimeClockSkew is not zero!");
    [self setMockDate:[NSDate dateWithTimeIntervalSince1970:3600]];
    
    AWSSES *ses = [AWSSES defaultSES];
    
    [[[ses getSendQuota:nil] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            XCTFail(@"Error: [%@]", task.error);
        }
        
        if (task.result) {
            XCTAssertTrue([task.result isKindOfClass:[AWSSESGetSendQuotaResponse class]]);
            AWSSESGetSendQuotaResponse *getSendQuotaResponse = task.result;
            XCTAssertTrue(getSendQuotaResponse.max24HourSend > 0);
            XCTAssertTrue(getSendQuotaResponse.maxSendRate > 0);
        }
        
        return nil;
    }] waitUntilFinished];
}

//EC2 Test
-(void)testClockSkewEC2
{
    XCTAssertFalse([NSDate az_getRuntimeClockSkew], @"current RunTimeClockSkew is not zero!");
    [self setMockDate:[NSDate dateWithTimeIntervalSince1970:3600]];
    
    AWSEC2 *ec2 = [AWSEC2 defaultEC2];
    
    AWSEC2DescribeInstancesRequest *describeInstancesRequest = [AWSEC2DescribeInstancesRequest new];
    [[[ec2 describeInstances:describeInstancesRequest] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            XCTFail(@"Error: [%@]", task.error);
        }
        
        if (task.result) {
            XCTAssertTrue([task.result isKindOfClass:[AWSEC2DescribeInstancesResult class]]);
            AWSEC2DescribeInstancesResult *describeInstancesResult = task.result;
            XCTAssertNotNil(describeInstancesResult.reservations);
        }
        
        return nil;
    }] waitUntilFinished];
}

//ELB Test
-(void)testClockSkewELB
{
    XCTAssertFalse([NSDate az_getRuntimeClockSkew], @"current RunTimeClockSkew is not zero!");
    [self setMockDate:[NSDate dateWithTimeIntervalSince1970:3600]];
    AWSElasticLoadBalancing *elb = [AWSElasticLoadBalancing defaultElasticLoadBalancing];
    
    AWSElasticLoadBalancingDescribeAccessPointsInput *describeAccessPointsInput = [AWSElasticLoadBalancingDescribeAccessPointsInput new];
    [[[elb describeLoadBalancers:describeAccessPointsInput] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            XCTFail(@"Error: [%@]", task.error);
        }
        
        if (task.result) {
            XCTAssertTrue([task.result isKindOfClass:[AWSElasticLoadBalancingDescribeAccessPointsOutput class]]);
            AWSElasticLoadBalancingDescribeAccessPointsOutput *describeAccessPointsOutput = task.result;
            XCTAssertNotNil(describeAccessPointsOutput.loadBalancerDescriptions, @"loadBalancerDescriptions Array should not be nil");
        }
        
        return nil;
    }] waitUntilFinished];
}

//AutoScaling Test
-(void)testClockSkewAS
{
    XCTAssertFalse([NSDate az_getRuntimeClockSkew], @"current RunTimeClockSkew is not zero!");
    [self setMockDate:[NSDate dateWithTimeIntervalSince1970:3600]];
    
    AWSAutoScaling *autoScaling = [AWSAutoScaling defaultAutoScaling];
    
    [[[autoScaling describeAccountLimits:nil] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            XCTFail(@"Error: [%@]", task.error);
        }
        
        if (task.result) {
            XCTAssertTrue([task.result isKindOfClass:[AWSAutoScalingDescribeAccountLimitsAnswer class]]);
            AWSAutoScalingDescribeAccountLimitsAnswer *describeAccountLimitsAnswer = task.result;
            XCTAssertNotNil(describeAccountLimitsAnswer.maxNumberOfAutoScalingGroups);
        }
        
        return nil;
    }] waitUntilFinished];
}

//STS Test
-(void)testClockSkewSTS
{
    XCTAssertFalse([NSDate az_getRuntimeClockSkew], @"current RunTimeClockSkew is not zero!");
    [self setMockDate:[NSDate dateWithTimeIntervalSince1970:3600]];
    
    AWSSTS *sts = [AWSSTS defaultSTS];
    
    AWSSTSGetSessionTokenRequest *getSessionTokenRequest = [AWSSTSGetSessionTokenRequest new];
    getSessionTokenRequest.durationSeconds = @900;
    
    [[[sts getSessionToken:getSessionTokenRequest] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            XCTFail(@"Error: [%@]", task.error);
        }
        
        if (task.result) {
            AWSSTSGetSessionTokenResponse *getSessionTokenResponse = task.result;
            XCTAssertTrue([getSessionTokenResponse.credentials.accessKeyId length] > 0);
            XCTAssertTrue([getSessionTokenResponse.credentials.secretAccessKey length] > 0);
            XCTAssertTrue([getSessionTokenResponse.credentials.sessionToken length] > 0);
            XCTAssertTrue([getSessionTokenResponse.credentials.expiration isKindOfClass:[NSDate class]]);
        }
        
        return nil;
    }] waitUntilFinished];

}

@end

#endif
