#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

@interface Beacon : NSObject <CBPeripheralManagerDelegate>
@property CBPeripheralManager * manager;
@property (readonly) NSUUID * uuid;
@property (readonly) NSInteger major;
@property (readonly) NSInteger minor;

-(instancetype) initWithUUID:(NSUUID *)uuid major:(NSInteger)major andMinor:(NSInteger)minor;
-(NSDictionary *) advertisement;

@end

@implementation Beacon
-(instancetype) initWithUUID:(NSUUID *)uuid major:(NSInteger)major andMinor:(NSInteger)minor {
  if (self = [super init]) {
    _manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    _uuid    = uuid;
    _major   = major;
    _minor   = minor;
  }
  
  return self;
}

-(void) peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
  if(peripheral.state == CBPeripheralManagerStatePoweredOn) {
    [peripheral startAdvertising:[self advertisement]];
    NSLog(@"Advertising iBeacon with UUID: %@, major: %zd, minor: %zd", [self.uuid UUIDString], self.major, self.minor);
  }
}

- (NSDictionary *)advertisement {
    NSString *beaconKey = @"kCBAdvDataAppleBeaconKey";
    
    unsigned char advertisement[21];
    
    [self.uuid getUUIDBytes:(unsigned char *)&advertisement];
    
    advertisement[16] = (unsigned char)(self.major >> 8);
    advertisement[17] = (unsigned char)(self.major & 255);
    advertisement[18] = (unsigned char)(self.minor >> 8);
    advertisement[19] = (unsigned char)(self.minor & 255);
    advertisement[20] = -59;
  
    return  @{beaconKey: [NSData dataWithBytes:advertisement length:21]};
}

@end

int main(int argc, const char * argv[])
{

  @autoreleasepool {
      NSUserDefaults * options = [NSUserDefaults standardUserDefaults];
    
      NSArray * requiredArguments = @[@"uuid", @"major", @"minor"];
    
      for (NSString * argument in requiredArguments) {
        if(![options objectForKey:argument]) {
          NSLog(@"Usage: ibeacon -uuid uuid -major major -minor");
          exit(1);
        }
      }

      NSUUID * uuid = [[NSUUID alloc] initWithUUIDString:[options stringForKey:@"uuid"]];
    
      Beacon * beacon = [[Beacon alloc] initWithUUID:uuid
                                                              major:[options integerForKey:@"major"]
                                                           andMinor:[options integerForKey:@"minor"]];
    
      NSLog(@"Setting up iBeacon with UUID: %@", [beacon.uuid UUIDString]);
    
      [[NSRunLoop currentRunLoop] run];
  }
    return 0;
}

