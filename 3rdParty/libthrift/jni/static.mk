#
# Thrift 0.8.0 prebuilt static C++ library
#

__WAS_PATH := $(LOCAL_PATH)
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := thrift_prebuilt_static
LOCAL_SRC_FILES := ../obj/local/$(TARGET_ARCH_ABI)/libthrift.a
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/..
LOCAL_EXPORT_CPPFLAGS := -DHAVE_CONFIG_H -D__GLIBC__

include $(PREBUILT_STATIC_LIBRARY)

LOCAL_PATH := $(__WAS_PATH)
