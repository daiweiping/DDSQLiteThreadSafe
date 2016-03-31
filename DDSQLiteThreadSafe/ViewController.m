//
//  ViewController.m
//  DDSQLiteThreadSafe
//
//  Created by MIMO on 16/3/31.
//  Copyright © 2016年 MIMO. All rights reserved.
//

#import "ViewController.h"
#import <sqlite3.h>

@interface ViewController ()

@end

@implementation ViewController{
    sqlite3 *db;
}


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dbPath = [documentPath stringByAppendingPathComponent:@"testDB.db"];
    
    /**
     *  配置线程模式，单线程：SQLITE_CONFIG_SINGLETHREAD；多线程：SQLITE_CONFIG_MULTITHREAD；串行：SQLITE_CONFIG_SERIALIZED
     */
    sqlite3_config(SQLITE_CONFIG_SERIALIZED);
    
    if (sqlite3_open(dbPath.UTF8String, &db) != SQLITE_OK) {
        NSLog(@"数据库打开失败");
        return;
    }
    char *create_table = "create table if not exists people(id integer primary key autoincrement, name text, phone integer, address text)";
    char *errmsg;
    if (sqlite3_exec(db,create_table,NULL,NULL,&errmsg) != SQLITE_OK) {
        NSLog(@"创建表失败:%s",errmsg);
        sqlite3_close(db);
        return;
    }
    
    /**
     *  默认情况下，iOS的SQLite线程模式为多线程模式，以下两个线程同时访问同一个数据库连接，会出现异常，解决办法的一种就是在sqlite3_open前配置线程模式sqlite3_config
     */
    dispatch_queue_t insertQueue = dispatch_queue_create("insertQueue", NULL);
    dispatch_async(insertQueue, ^{
        [self insert];
    });
    
    dispatch_queue_t deleteQueue = dispatch_queue_create("deleteQueue", NULL);
    dispatch_async(deleteQueue, ^{
        [self delete];
    });
    
}

- (void)insert{
    
    for (int i = 0; i < 100; i ++) {
        NSString *name = [NSString stringWithFormat:@"name_%02d",i];
        NSString *phone = [NSString stringWithFormat:@"18718873%02d",i];
        NSString *address = [NSString stringWithFormat:@"address_%02d",i];
        
        NSString *insert_statement = [NSString stringWithFormat:@"insert into people (name, phone, address) values ('%@', '%@', '%@');",name,phone,address];
        char *errmsg = NULL;
        
        if (sqlite3_exec(db, insert_statement.UTF8String, NULL, NULL, &errmsg) != SQLITE_OK) {
            NSLog(@"插入记录失败 >> %s",errmsg);
            return;
        }
        
    }
}

-(void)delete{
    
    for (int i = 0; i < 100; i ++) {
        NSString *name = [NSString stringWithFormat:@"name_%02d",i];
        NSString *delete_statement = [NSString stringWithFormat:@"delete from people where name = '%@'",name];
        char *errmsg = NULL;
        
        if (sqlite3_exec(db, delete_statement.UTF8String, NULL, NULL, &errmsg) != SQLITE_OK) {
            NSLog(@"删除记录失败 >> %s",errmsg);
            return;
        }
    }
}

@end
